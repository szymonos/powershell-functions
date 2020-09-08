<#
.Description
AzCopy is a command-line utility designed for copying data to/from Microsoft Azure Blob, File, and Table storage,
using simple commands designed for optimal performance. You can copy data between a file system and a storage account,
or between storage accounts.
.Synopsis
https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy
https://docs.microsoft.com/en-us/azure/storage/common/storage-performance-checklist
.Example
.\Admin\AzCopy.ps1
#>

# common parameters
$azcopy = 'C:\usr\AZCopy\azcopy.exe'
$file2Copy = 'D:\Source\bacpac\ABCUFOSTAGE1\RMA_190926.bacpac'

# destination storage account/blob[/folder] to copy the file to
$destFolder = 'https://alsoildevstorage.blob.core.windows.net/sqlbackups'

# obtained in Shared access signature section of Storage Account
$accessSignature = '?sv=2018-03-28&ss=bfqt&srt=sco&sp=rwdlacup&se=2019-09-27T01:35:38Z&st=2019-09-26T17:35:38Z&spr=https&sig=4xRhRK4B%2F5H%2Bgm55EWsa7Pn%2FrkWdauqi5aK33fL8fkM%3D'

# Checking for correct path to azcopy tool
if (!(Test-Path $azcopy)) {
    $azcopy = Get-ChildItem -Path 'C:\' -Filter 'azcopy.exe' -File -Recurse -Exclude 'C:\Windows' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if ($null -eq $azcopy) {
    Write-Host "Error: azcopy.exe not found.`nPlease download AzCopy from https://aka.ms/downloadazcopy-v10-windows." -ForegroundColor Red
    Break
}

&$azcopy login --tenant-id='95924808-3044-4177-9c1b-713746ffab95' # ALSO Holding AG

$destination = $destFolder, (Split-Path $file2Copy -Leaf) -join('/')
$destSignature = $destination + $accessSignature
$copyDuration = Measure-Command{ &$azcopy copy $file2Copy $destSignature --overwrite=false --follow-symlinks --recursive --from-to=LocalBlob --blob-type=BlockBlob --put-md5}
$copyDuration = @{'CopyDuration'= $copyDuration.ToString('hh\:mm\:ss\.fff')}; New-Object psobject -Property $copyDuration
