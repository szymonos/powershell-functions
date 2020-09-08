<#
.SYNOPSIS
Compute file hash required for model.xml file in bacpac
.LINK
https://stackoverflow.com/questions/42028861/error-importing-azure-bacpac-file-to-local-db-error-incorrect-syntax-near-extern
.EXAMPLE
db\SQLServer\SqlPackageClean.ps1
db\SQLServer\SqlPackageClean.ps1 -pacFile 'C:\Source\dacpac\also-ecom\XLINK.dacpac'
db\SQLServer\SqlPackageClean.ps1 -ModelXmlPath 'C:\Source\bacpac\also-ecom\LANG\model.xml'
#>

param(
    [cmdletbinding()]
    [ValidateScript( { Test-Path $_ -PathType 'Leaf' })]$pacFile
)

# Include functions
. '.include\func_io.ps1'
. '.include\func_forms.ps1'

# Select model.xml
$pacFile ??= Get-FileName -InitialDirectory 'C:\Source' -FileFilter 'SQL Package|*.bacpac;*.dacpac'

if ([System.IO.Path]::GetExtension($pacFile) -notin ('.bacpac', '.dacpac')) {
    Write-Warning ('Selected file is not sql package')
    break
}

# Rename pac file to zip
$zipFile = Rename-Item -Path $pacFile -NewName (([System.IO.Path]::GetFileNameWithoutExtension($pacFile)) + '.zip') -PassThru

$destDir = Join-Path $zipFile.DirectoryName -ChildPath $zipFile.BaseName
if (!(Test-Path $destDir)) {
    New-Item -Path $destDir -ItemType Directory | Out-Null
} else {
    Get-ChildItem $destDir -Recurse | Remove-Item -Recurse -Force
}

#
Write-Output ("`e[38;5;51mExtracting pac file`e[0m")
Expand-Archive -Path $zipFile -DestinationPath $destDir

# Clean model.xml from DatabaseScopedConfiguration
Write-Output ('Extracting model.xml from pac file')
$modelXml = Join-Path $destDir -ChildPath 'model.xml'
Write-Output ("`e[38;5;51mImporting model.xml to xml variable`e[0m")
[xml]$model = Get-Content $modelXml
# Add xml namespace
$ns = New-Object Xml.XmlNamespaceManager $model.NameTable
$ns.AddNamespace('dac', $model.DataSchemaModel.xmlns)
# Remove DatabaseScoped features from database model
Write-Output ("`e[38;5;51mRemoving unsupported features from model`e[0m")
$model.SelectNodes('//dac:Relationship[@Name="GenericDatabaseScopedConfigurationOptions"]', $ns) | ForEach-Object {
    $_.ParentNode.RemoveChild($_)
}
$model.SelectSingleNode('//dac:Element[@Type="SqlGenericDatabaseScopedConfigurationOptions"]', $ns) | ForEach-Object {
    $_.ParentNode.RemoveChild($_)
}
$model.SelectNodes('//dac:Element[starts-with(@Type, "SqlExternal")]', $ns) | ForEach-Object {
    $_.ParentNode.RemoveChild($_)
}
$model.SelectNodes('//dac:Element[starts-with(@Name,"[Grant.AlterAnyDatabaseEventSession.Database]")]', $ns) | ForEach-Object {
    $_.ParentNode.RemoveChild($_)
}
$model.Save($modelXml)

# Clean model variable and run garbage collector
Remove-Variable model
[System.GC]::Collect()

# Return file hash
$modelHash = (Get-FileHash $modelXml -Algorithm 'SHA256').Hash

# Add new model.xml sha hash to Origin.xml
Write-Output ("`e[38;5;51mModify model.xml checksum in Origin.xml`e[0m")
$originXml = Join-Path $destDir -ChildPath 'Origin.xml'
[xml]$origin = Get-Content $originXml
$origin.DacOrigin.Checksums.Checksum.'#text' = $modelHash
$origin.DacOrigin.PackageProperties.ContainsExportedData = 'false'
$node = $origin.DacOrigin.ExportStatistics
$node.ParentNode.RemoveChild($node)
$origin.Save($originXml)

## Change definition to dacpac
Write-Output ("`e[38;5;51mChange definition to dacpac`e[0m")
# [Content_Types].xml
$contentXml = Join-Path $destDir -ChildPath '[Content_Types].xml'
[xml]$content = Get-Content -LiteralPath $contentXml
$content.Types.Default | Where-Object -Property Extension -in ('BCP', 'rels') | Foreach-Object {
    $_.ParentNode.RemoveChild($_)
}
$content.Save($contentXml)

# DacMetadata.xml
$metadataXml = Join-Path $destDir -ChildPath 'DacMetadata.xml'
[xml]$metadata = Get-Content -LiteralPath $metadataXml
$metadata.DacType.Version = '1.0'
$metadata.Save($metadataXml)

# Rename back zip to pac file
Rename-Item -Path $zipFile -NewName (Split-Path $pacFile -Leaf)

# Add modified xml files back to zipFile
Write-Output ("`e[38;5;51mAdding updated files to database pac file`e[0m")
$dacFile = $pacFile.Replace('bac', 'dac')
if(!(Test-Path(Split-Path $dacFile))) {
    New-Item (Split-Path $dacFile) -ItemType Directory | Out-Null
}
Compress-Archive -Path (Join-Path $destDir -ChildPath '*.xml') -DestinationPath $dacFile -Update
#7z.exe a -tzip $dacFile (Join-Path $destDir -ChildPath '*.xml')

Write-Output ("`e[32mDone!`e[0m")
