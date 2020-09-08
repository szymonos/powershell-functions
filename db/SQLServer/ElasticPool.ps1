<#
# Set subscription
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
(Get-AzContext).Subscription.Name
#>

param (
    [Parameter(Mandatory = $false)][string]$Server = 'also-ecom'
)

. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

Write-Output 'Getting list of SQL Servers'
$sqlServers = Import-Csv '.\.assets\config\Az\az_sqlservers.csv'

if ([string]::IsNullOrEmpty($Server)) {
    Write-Output 'Select server for processing'
    $sqlServers | Format-Table -AutoSize -Property Id, ServerName, Subscription
    $srvId = Read-Host -Prompt 'Id'
    $srv = $sqlServers | Where-Object { $_.Id -eq $srvId }
} else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
}
if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

Connect-Subscription -Subscription $srv.SubscriptionId | Select-Object -ExpandProperty Name

<#
$srv = $sqlServers | Where-Object { $_.RowKey -eq 0 }
#>

<## Set elastic pool name ##>
$PoolName = 'ep-ecom-back'

# Set rest of variables
$location = $srv.Location
$serverName = $srv.ServerName
$resourceGroupName = $srv.ResourceGroupName

# Create resource group
Get-AzResourceGroup | Format-Table -AutoSize -Property ResourceGroupName, Location
$newRG = $false
if ($newRG) {
    $resourceGroupName = 'NewResGroupName'
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create elastic database pool
$Pool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $PoolName -Edition 'GeneralPurpose' -vCore 2 -ComputeGeneration 'Gen5'
$Pool = New-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $PoolName -Edition 'Standard' -Dtu 100
Remove-AzSqlElasticPool -ElasticPoolName $PoolName

# Get existing elastic pools on the server
$Pool = Get-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName
$Pool | Select-Object -Property ResourceGroupName, ServerName, ElasticPoolName, SkuName, Capacity, StorageMB

# Move the database to the pool
$database = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -ElasticPoolName $PoolName

# Move the database into a standalone performance level
$database = Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -RequestedServiceObjectiveName "S0"

$database | Select-Object -Property ResourceGroupName, ServerName, DatabaseName, SkuName, Capacity, StorageMB
# Clean up deployment
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName

Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -vCore 8 -Edition BusinessCritical -StorageMB 1048576

$resourceGroupName = 'Also-Ecom-PROD'
$serverName = 'also-ecom'
$elasticPool = 'ep-ecom-back'
$elasticPool = 'ep-ecom-front'
Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPool -Edition 'BusinessCritical' -ComputeGeneration 'Gen5' -vCore 6 -ZoneRedundant 1 -StorageMB 774144
Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPool -Edition 'GeneralPurpose' -ComputeGeneration 'Gen5' -vCore 6 -StorageMB 1572864
Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPool -Edition 'GeneralPurpose'
Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPool -vCore 8 -Edition BusinessCritical

Get-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPool | Select-Object *

$resourceGroupName = 'Also-Ecom-PROD'
$serverName = 'also-ecom'
$elasticPoolF = 'ep-ecom-front'
$edition = 'BusinessCritical'
$gen = 'Gen5'
$licenseType = 'BasePrice'
$storage = 524288
$coresDown = 12
$coresUp = 32
Get-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF | Select-Object *

$scaleDown = { Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -DatabaseVCoreMin $coresDown -DatabaseVCoreMax $coresDown }
$scaleDown = { Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -Edition $edition -ComputeGeneration $gen -DatabaseVCoreMin $coresDown -DatabaseVCoreMax $coresDown -vCore $coresDown -StorageMB $storage -ZoneRedundant }
$switchDown = Measure-Command { & $scaleDown }; Write-Host $switchDown.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow
$switchDown = Measure-Command { Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -Edition $edition -ComputeGeneration $gen -vCore $coresDown -StorageMB $storage -ZoneRedundant }; Write-Host $switchDown.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow

$scaleUp = { Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -Edition $edition -ComputeGeneration $gen -vCore $coresUp -StorageMB $storage -ZoneRedundant -LicenseType $licenseType }
$switchUp = Measure-Command { & $scaleUp }; Write-Host $switchUp.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow

Set-AzSqlElasticPool -ElasticPoolName 'ep-ecom-front' -ServerName 'also-ecom' -ResourceGroupName 'Also-Ecom-PROD' -Edition 'BusinessCritical' -StorageMB '524288' -ComputeGeneration 'Gen5' -VCore 16 -LicenseType 'BasePrice' -DatabaseVCoreMin
Get-AzSqlElasticPool -ElasticPoolName 'ep-ecom-front' -ServerName 'also-ecom' -ResourceGroupName 'Also-Ecom-PROD'

$setEpGP = {Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -Edition 'GeneralPurpose' -ComputeGeneration 'Gen5' -vCore 6 -StorageMB 774144}
$switchEp = Measure-Command {& $setEpGP}; Write-Host $switchEP.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow

Set-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolF -Edition 'BusinessCritical' -vCore 8 -ZoneRedundant -StorageMB 774144 -WhatIf

$elasticPoolB = 'ep-ecom-back'
Get-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolB | Select-Object *
