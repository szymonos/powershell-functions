<#
.SYNOPSIS
Compute file hash required for model.xml file in bacpac
.LINK
https://stackoverflow.com/questions/42028861/error-importing-azure-bacpac-file-to-local-db-error-incorrect-syntax-near-extern
.EXAMPLE
db\SQLServer\SqlPackageClean.ps1
db\SQLServer\SqlPackageClean.ps1 -pacFile 'C:\Source\dacpac\also-ecom\XLINK.dacpac'
#>

param(
    [cmdletbinding()]
    [ValidateScript( { Test-Path $_ -PathType 'Leaf' })]$pacFile
)
$ErrorActionPreference = 'Stop'
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

# Clean model.xml from DatabaseScopedConfiguration
Write-Output ('Extracting model.xml from pac file')
$modelXml = Get-FileFromZip -ZipFile $zipFile -Destination $destDir -FileToGet 'model.xml' -PassThru
Write-Output ('Importing model.xml to xml variable')
[xml]$model = Get-Content $modelXml
# Add xml namespace
$ns = New-Object Xml.XmlNamespaceManager $model.NameTable
$ns.AddNamespace('dac', $model.DataSchemaModel.xmlns)
# Remove DatabaseScoped features from database model
Write-Output ('Removing unsupported features from model')
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
Write-Output ('Extracting Origin.xml from pac file')
$originXml = Get-FileFromZip -ZipFile $zipFile -Destination $destDir -FileToGet 'Origin.xml' -PassThru
Write-Output ('Modify model.xml checksum in Origin.xml')
[xml]$origin = Get-Content $originXml
$origin.DacOrigin.Checksums.Checksum.'#text' = $modelHash
$origin.Save($originXml)

# Add modified xml files back to zipFile
Write-Output ('Adding updated files to database pac file')
#Compress-Archive -Path $originXml, $modelXml -DestinationPath $zipFile.FullName -Update
7z.exe a -tzip $zipFile $modelXml $originXml

# Rename back zip to pac file
Rename-Item -Path $zipFile -NewName (Split-Path $pacFile -Leaf)
Write-Output ("`e[32mDone!`e[0m")
