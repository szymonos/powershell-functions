<#
# Set subscription
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
(Get-AzContext).Subscription.Name
#>
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

$resourceGroupName = 'Also-Ecom-PROD'
$serverName = 'also-ecom'
$databaseName = 'XLINK'
# $edition = 'BusinessCritical'
# $gen = 'Gen5'
$licenseType = 'BasePrice'

Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName | Select-Object -Property * -ExcludeProperty ResourceId, DatabaseId, CatalogCollation, CurrentServiceObjectiveId, RequestedServiceObjectiveId, Tags, CreateMode

$dbProp = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName | Select-Object -Property ResourceId, MaxSizeBytes
$usedBytes = (Get-AzMetric -ResourceId $dbProp.ResourceId -MetricName 'storage' -StartTime (Get-Date).AddMinutes(-2)).Data | Select-Object -First 1 -ExpandProperty Maximum
if ($usedBytes / $dbProp.MaxSizeBytes -gt 0.9) {
    $sizeBytes = [Math]::Ceiling($usedBytes * 1.2 / 64GB) * 64GB
    Write-Output ('Requested size: ' + $sizeBytes / 1GB + 'GB')
} else {
    $sizeBytes = $dbProp.MaxSizeBytes
    Write-Output ('Scale not required')
}

$reqSvc = 'BC_Gen5_32'
#$reqSvc = 'BC_Gen5_12'

$scaleCmd = { Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -RequestedServiceObjectiveName $reqSvc -MaxSizeBytes $sizeBytes -LicenseType $licenseType -ZoneRedundant }
$scaleExec = Measure-Command { & $scaleCmd }; Write-Host $scaleExec.ToString('hh\:mm\:ss\.fff') -ForegroundColor Yellow
