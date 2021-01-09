<#
.SYNOPSIS
Script converting files encoding. At dafault settings converts all files in subdirectories from utf8BOM to utf8.
It also change end of line from CRLF to LF.
.EXAMPLE
.tools\EncodingChange.ps1 -InitialDirectory 'H:\Users\szymo\OneDrive\Git\PowerShell\.tools'
.tools\EncodingChange.ps1 -Filter '*.sql' -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL'
.tools\EncodingChange.ps1 -SourceEncoding 'windows-1250' -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL'
.tools\EncodingChange.ps1 -SourceEncoding 'utf8' -DestinationEncoding 'utf8BOM' -Filter ''*.sql -InitialDirectory 'H:\Users\szymo\OneDrive\Git\SQL\'
#>

param (
    $SourceEncoding,
    $DestinationEncoding = 'utf8',
    $FolderExclude = '.\\\.\w+|cache',  # RegEx excluding directories starting with . and including cache
    $FileFilter = '*',
    [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$InitialDirectory #= 'H:\Source\Repos\ADO-CDP\CDP_ETL_FAPP'
)

[array]$folderList = $InitialDirectory
$folderList += (Get-ChildItem -Path $InitialDirectory -Directory -Recurse | Where-Object { $_.FullName -notmatch $FolderExclude}).FullName
foreach ($folder in $folderList) {
    #$folder = $folderList[0]
    Write-Output ('Processing folder: ' + $folder)
    $fileList = (Get-ChildItem -Path $folder -Filter $FileFilter -File).FullName
    foreach ($fullName in $fileList) {
        #$fullName = $fileList[6]
        if ($SourceEncoding) {
            $content = (Get-Content -Path $fullName -Encoding $SourceEncoding) -replace "`r`n", "`n"
        }
        else {
            $content = (Get-Content -Path $fullName) -replace "`r`n", "`n"
        }
        Set-Content -Path $fullName -Value $content -Encoding $DestinationEncoding -Force
    }
}
