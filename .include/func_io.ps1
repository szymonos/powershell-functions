<#
.SYNOPSIS
Functions using methods from System.IO namespace
.EXAMPLE
. '.include\func_io.ps1'
#>
[void] [System.Reflection.Assembly]::Load('System.IO.Compression.FileSystem')
function Get-FileFromZip {
    param(
        [cmdletbinding()]
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' } )][string]$ZipFile,
        [ValidateScript( { Test-Path $_ -PathType 'Container' } )][string]$Destination,
        [Parameter(Mandatory = $true)][string]$FileToGet,
        [switch]$PassThru
    )
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipFile)
        $entries = $zip.Entries | Where-Object -Property Name -like ($FileToGet -replace '[$^{[()+]', '`$&')
        foreach ($entry in $entries) {
            $destFile = Join-Path $destDir -ChildPath $entry.Name
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destFile, $true)
            if ($PassThru) { $destFile }
        }
        if (!$PassThru) { ('Successfully extracted {0} file(s) from {1}' -f $entries.Count , ([System.IO.Path]::GetFileName($ZipFile))) }
        $zip.Dispose()
    }
    catch {
        Write-Warning "Failed to get $FileToAdd from $ZipFile."
    }
}
function Add-FileToZip {
    param(
        [cmdletbinding()]
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' } )][string]$ZipFile,
        [ValidateScript( { Test-Path $_ -PathType 'Leaf' } )][string]$FileToAdd
    )
    try {
        $zip = [System.IO.Compression.ZipFile]::Open($ZipFile, 'Update')
        $FileName = [System.IO.Path]::GetFileName($FileToAdd)
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $FileToAdd, $FileName, 'Optimal') | Out-Null
        $Zip.Dispose()
        ('Successfully added {0} to {1}' -f $FileName, ([System.IO.Path]::GetFileName($ZipFile)))
    }
    catch {
        Write-Warning "Failed to add $FileToAdd to $ZipFile. Details: $_"
    }
}
