<#
.SYNOPSIS
Converts all csv files found in provided directory to xlsx
.LINK
https://docs.microsoft.com/en-us/office/vba/api/Word.SaveAs2
.PARAMETER Directory
Specify directory containing documents to convert
.EXAMPLE
.tools\Docx2Pdf.ps1
.tools\Docx2Pdf.ps1 -Directory 'C:\temp'
#>

param(
    [cmdletbinding()]
    [ValidateScript( { Test-Path $_ -PathType 'Container' } )]$Directory
)
$ErrorActionPreference = 'SilentlyContinue'

# Include functions
. '.include\func_forms.ps1'

$Directory ??= Get-Folder

$searchFiles = Get-ChildItem -Path $Directory -Filter '*.docx' -File -Recurse
[Console]::WriteLine("`e[38;5;51mFound {0} file(s).`e[0m", $searchFiles.Count)
if ($searchFiles.Count -gt 0) {
    # Create Word instance
    $comObj = New-Object -ComObject Word.Application
    foreach ($file in $searchFiles) {
        $dstFile = Join-Path -Path $file.DirectoryName -ChildPath ($file.BaseName + '.pdf') # destination xlsx file path
        Remove-Item -Path $dstFile -Force -ErrorAction SilentlyContinue # remove existing file
        $comObj.Documents.Open($file.FullName).SaveAs2($dstFile, 17)
        $dstFile
    }
}

# Close Word instance and stop the process
$comObj.Quit()
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObj) | Out-Null

[Console]::WriteLine("`e[92mDone!`e[0m")
