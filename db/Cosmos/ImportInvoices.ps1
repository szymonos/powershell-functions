<#
.Synopsis
Script used to import invoices from SQL Server to Azure Cosmos DB

.Description
Script does work in 3 steps:
1. Imports invoices splited by months from the current to oldest specified period to json file.
2. Fixes json formating for nested invoice lines and saves fixed json file.
3. Exports fixed json file to specified collection in Azure Cosmos DB.
   It creates log files for every month for error debugging purposes (empty log files are deleted).

DocumentDB Data Migration Tool required for the script to work
https://docs.microsoft.com/en-us/azure/cosmos-db/import-data

.Example
CosmosDB\ImportInvoices.ps1
#>

# DocumentDB Data Migration Tool path
$dt = 'C:\usr\drop\dt.exe'
if (!(Test-Path $dt)) {
    $dt = Get-ChildItem -Path 'C:\' -Filter 'dt.exe' -File -Recurse -Exclude 'C:\Windows' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
}
if ($null -eq $dt) {
    Write-Warning "Error: dt.exe not found.`nPlease install DocumentDB Data Migration Tool from https://aka.ms/csdmtool."
    Break
}

## Common parameters for exporting data from SQL and importing to CosmosDB
# specify server and database to connect to
$connectionString = 'Server=UFO3XSTAGE;Database=XLINK;Trusted_Connection=True;'
# specify AccountEndpont (obtained in Keys section of Azure Cosmos DB)
$accountEndpoint = 'https://also-cosmos-dev.documents.azure.com:443/;AccountKey=Key==;Database=XLINK'
# specify collection name
$colName = 'Invoices'
# specify local directory where json files will be imported and processed
$workingDir = 'D:\Source\V3Invoices'
$loggDir = Join-Path -Path $workingDir -ChildPath 'logs'
## Clean directory with error logs
Get-ChildItem -Path $loggDir -Filter 'errorlog_*.csv' | Remove-Item -Force -ErrorAction SilentlyContinue

## Create list of periods to proceed
$i = 0
[array]$periodsArray = @()
[datetime]$firstPeriod = '2018-01-01'   # earliest period to proceed
#[datetime]$firstPeriod = '1999-06-01'   # earliest period to proceed
[datetime]$lastPeriod = (Get-Date).ToString('yyyy-MM-') + '01'
[datetime]$startDate = Get-Date         # initialize startDate for the loop
while ($startDate -gt $firstPeriod) {
    [datetime]$startDate = $lastPeriod.AddMonths(-$i)
    [datetime]$endDate = ($lastPeriod.AddMonths(-$i + 1)).AddDays(-1)
    $prop = [ordered]@{
        StartDate = $startDate;
        EndDate   = $endDate
    }
    $periodsArray += New-Object -TypeName psobject -Property $prop
    $i = $i + 1
}

## Transfer data from SQL Server to Cosmos DB
foreach ($period in $periodsArray) {
    #$period = $periodsArray[0]
    [string]$startDate = $period.StartDate.ToString('yyyyMMdd')
    [string]$endDate = $period.EndDate.ToString('yyyyMMdd')
    Write-Host ('Proceeding period: ' + $period.StartDate.ToString('yyyy.MM.dd') + ' - ' + $period.EndDate.ToString('yyyy.MM.dd')) -ForegroundColor Magenta
    # set parameters for SQL query
    $sqlQuery = "exec dbo.V3InvoicesJSON @startdate = '" + $startDate + "', @enddate = '" + $endDate + "'"
    # set working files names
    $dstFile = Join-Path -Path $workingDir -ChildPath ('dt_' + $startDate + '.json')
    $fixedFile = Join-Path -Path $workingDir -ChildPath ('dtfixed_' + $startDate + '.json')
    $errorLogFile = Join-Path -Path $loggDir -ChildPath ('errorlog_' + $startDate + '.csv')

    # import data from SQL Server for current period
    &$dt /s:SQL /s.ConnectionString:$connectionString /s.Query:$sqlQuery /t:JsonFile /t.File:$dstFile /t.Prettify /t.Overwrite

    # regexp filter definitions to fix json formating for nested invoice lines
    filter repl1 { $_ -replace '"Lines": "\[', '"Lines": [' }
    filter repl2 { $_ -replace '{\\"OID\\":\\"', '{"OID":"' }
    filter repl3 { $_ -replace '\\",\\"PID\\":\\"', '","PID":"' }
    filter repl4 { $_ -replace '\\",\\"Qty\\":', '","Qty":' }
    filter repl5 { $_ -replace ',\\"Price\\":', ',"Price":' }
    filter repl6 { $_ -replace ',\\"Value\\":', ',"Value":' }
    filter repl7 { $_ -replace ',\\"ValueVAT\\":', ',"ValueVAT":' }
    filter repl8 { $_ -replace ',\\"OrderLine\\":', ',"OrderLine":' }
    filter repl9 { $_ -replace ',\\"ProductType\\":\\"', ',"ProductType":"' }
    filter repl10 { $_ -replace '\\",\\"ParentLNr\\":', '","ParentLNr":' }
    filter repl11 { $_ -replace ',\\"StockNo\\":\\"', ',"StockNo":"' }
    filter repl12 { $_ -replace '\\",\\"ProductName\\":\\"', '","ProductName":"' }
    filter repl13 { $_ -replace '\\"},{', '"},{' }
    filter repl14 { $_ -replace '\\"}]"', '"}]' }
    # clear fixed json file if exists
    if (Test-Path $fixedFile) { Clear-Content $fixedFile }
    Write-Host 'Fixing json formating for nested invoice lines ' -ForegroundColor Cyan -NoNewline
    # fix json formating for nested invoice lines
    $fixDuration = Measure-Command{Get-Content -Raw $dstFile | repl1 | repl2 | repl3 | repl4 | repl5 | repl6 | repl7 | repl8 | repl9 | repl10 | repl11 | repl12 | repl13 | repl14 | Add-Content $fixedFile}
    Write-Host $fixDuration.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow
    # force Garbage Collector to dispose data in memory
    [GC]::Collect()
    Remove-Item $dstFile -Force

    # import json to CosmosDB
    &$dt /s:JsonFile /s.Files:$fixedFile /t:DocumentDB /t.ConnectionString:AccountEndpoint=$accountEndpoint /t.ConnectionMode:Gateway /t.Collection:$colName /ErrorLog:$errorLogFile

    # remove error log file and fixed json file if there were no errors
    $emptyErrorLog = Get-Item -Path $errorLogFile | Where-Object { $_.Length -eq 0 }
    if ($null -ne $emptyErrorLog) {
        Remove-Item $errorLogFile -Force
        Remove-Item $fixedFile -Force
    }
    Write-Output ''
}
