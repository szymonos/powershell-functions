<#
.SYNOPSIS
Script converting files encoding. At dafault settings converts all files in subdirectories from utf8BOM to utf8.
.EXAMPLE
.tools\EncodingChange.ps1 -InitialDirectory 'H:\Users\szymo\OneDrive\Git\PowerShell\.tools'
.tools\EncodingChange.ps1 -Filter '*.sql' -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL'
.tools\EncodingChange.ps1 -SourceEncoding 'windows-1250' -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL'
.tools\EncodingChange.ps1 -SourceEncoding 'utf8' -DestinationEncoding 'utf8BOM' -Filter ''*.sql -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL\'
#>

param (
    $SourceEncoding,
    $DestinationEncoding = 'utf8',
    $Filter = '*',
    [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$InitialDirectory = $env:TEMP
)

$startDir = $PWD
Set-Location $InitialDirectory

$folderList = Get-ChildItem -Directory -Exclude '.git'
foreach ($folder in $folderList) {
    #$folder = $folderList[0]
    Write-Output ('Processing folder: ' + $folder.FullName)
    $fileList = (Get-ChildItem -Path $folder -Filter $Filter -File -Recurse -Force).FullName
    foreach ($fullName in $fileList) {
        #$fullName = $fileList[6]
        if ($SourceEncoding) {
            $content = Get-Content -Path $fullName -Encoding $SourceEncoding -replace "`r`n", "`n"
        } else {
            $content = Get-Content -Path $fullName -replace "`r`n", "`n"
        }
        Set-Content -Path $fullName -Value $content -Encoding $DestinationEncoding -NoNewline -Force
    }
}

Set-Location $startDir
