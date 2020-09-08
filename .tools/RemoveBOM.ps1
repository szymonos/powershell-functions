<#
.EXAMPLE
.tools\RemoveBOM.ps1
#>

$utf8Encoding = New-Object System.Text.UTF8Encoding($False)
$source = '.\'

$folderList = Get-ChildItem -Path $source -Directory -Exclude '.git'
foreach ($folder in $folderList) {
    Write-Output ('Processing folder: ' + $folder)
    $fileList = (Get-ChildItem -Path $folder -Recurse -File -Force).FullName
    foreach ($fullName in $fileList) {
        #$fullName = $fileList[0]
        $content = Get-Content $fullName
        if ($null -eq $content) {
            [System.IO.File]::WriteAllText($fullName, '', $utf8Encoding)
        } else {
            [System.IO.File]::WriteAllLines($fullName, $content, $utf8Encoding)
        }
    }
}
