<#
.SYNOPSIS
Splits csv file to multiple files in different folders determined by parameters folderUnique and fileUnique
.EXAMPLE
.tools\CsvSplit.ps1
#>

# Input parameters
$InputFile = '.\.assets\config\Az\az_sqldatabases.csv'
$OutputDir = '.\.assets\export\DBsByServer'
$folderUnique = 'Subscription'
$fileUnique = 'ServerName'

$csvImported = Import-Csv $InputFile

$allFolders = $csvImported | Select-Object -ExpandProperty $folderUnique -Unique
$allFiles = $csvImported | Select-Object -Property $folderUnique, $fileUnique -Unique

foreach ($folder in $allFolders) {
    #$folder = $allFolders[0]
    $dstFolder = Join-Path -Path $OutputDir -ChildPath $folder
    if (!(Test-Path $dstFolder)) {
        New-Item -Path $dstFolder -ItemType Directory | Out-Null
    }
    $folderFiles = ($allFiles | Where-Object -Property $folderUnique -eq $folder).$fileUnique
    foreach ($file in $folderFiles) {
        #$file = $folderFiles[2]
        $csvFile = $csvImported | Where-Object { $_.$folderUnique -eq $folder -and $_.$fileUnique -eq $file }
        $filename = Join-Path -Path $dstFolder -ChildPath "enum_$($file).csv"
        $csvFile | Export-Csv -Path $filename -NoTypeInformation -Encoding utf8
    }
}
