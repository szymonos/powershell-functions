<# Quickly check database connectivity
sqlcmd -S also-ecom-dev.database.windows.net -d XLINK -U SearchService -P 'pass' -Q "select 'Pass' as Test"
#>

$downloads = Get-ItemPropertyValue -Path 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name '{374DE290-123F-4565-9164-39C4925E467B}'
$fileName = 'GFK'; $queryFile = Join-Path -Path $downloads -ChildPath "$fileName.sql"
$srv = 'UFO3X'; sqlcmd -S $srv -i $queryFile -o ('.\.assets\logs\sqlcmd_' + $srv + '_' + (Get-Date).ToString('yyMMddHHmm') + '.log')
