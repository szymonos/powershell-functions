<#
.SYNOPSIS
Converts all csv files found in provided directory to xlsx
.LINK
https://stackoverflow.com/questions/39044995/how-can-i-stop-excel-processes-from-running-in-the-background-after-a-powershell
.PARAMETER Directory
Specify directory containing documents to convert
.EXAMPLE
.tools\Csv2Xlsx.ps1
.tools\Csv2Xlsx.ps1 -Directory '.\.assets\export\DBsByServer'
#>

param(
    [cmdletbinding()]
    [Parameter(Mandatory = $false)]$Directory
)
$ErrorActionPreference = 'SilentlyContinue'

# Include functions
. '.include\func_forms.ps1'

if (!(Test-Path $Directory)) {
    $Directory = Get-Folder
}

$searchFiles = Get-ChildItem -Path $Directory -Filter '*.csv' -File -Recurse
[Console]::WriteLine("`e[38;5;51mFound {0} file(s).`e[0m", $searchFiles.Count)
if ($searchFiles.Count -gt 0) {
    # Create Excel instance
    $comObj = New-Object -ComObject Excel.Application
    foreach ($file in $searchFiles) {
        $dstFile = Join-Path -Path $file.DirectoryName -ChildPath ($file.BaseName + '.xlsx') # destination xlsx file path
        Remove-Item -Path $dstFile -Force -ErrorAction SilentlyContinue # remove existing file
        $comObj.Workbooks.Open($file.FullName).SaveAs($dstFile, 51)
        $comObj.Quit()
        $dstFile
    }
}

# Release COM object
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObj) | Out-Null
[System.GC]::Collect()

[Console]::WriteLine("`e[92mDone!`e[0m")
