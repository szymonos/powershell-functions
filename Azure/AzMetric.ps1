<#
.Description
https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-how-to-manage-redis-cache-powershell
https://docs.microsoft.com/en-us/azure/azure-monitor/platform/metrics-supported
# Set subscription
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
(Get-AzContext).Subscription.Name
.Example
Redis\RedisCachManage.ps1
#>

$ResourceGroupName = 'Also-Ecom-PROD'
$ServerName = 'also-ecom'
$ElasticPoolName = 'ep-ecom-back'

## Get resource properties
$epProp = Get-AzSqlElasticPool -ResourceGroupName $resourceGroupName -ServerName $serverName -ElasticPoolName $elasticPoolName | `
    Select-Object -Property ResourceId, Capacity, MaxSizeBytes, StorageMB

# Get metric definitions for selected resource
$resId = $epProp.ResourceId
$idDef = (Get-AzMetricDefinition -ResourceId $resId | Select-Object -ExpandProperty Id -Last 1 | Split-Path).Replace('\', '/') + "/"
Get-AzMetricDefinition -ResourceId $epProp.ResourceId | Select-Object -Property @{Name = 'MetricName'; Expression = { $_.Id -replace ($idDef, '') } }, PrimaryAggregationType

# Get specific resource metric
$metricName = 'allocated_data_storage_percent'; $aggregationType = 'Maximum'
$metricName = 'allocated_data_storage'; $aggregationType = 'Average'
(Get-AzMetric -ResourceId $epProp.ResourceId -MetricName $metricName -StartTime (Get-Date).AddMinutes(-2)).Data | Select-Object -First 1 -ExpandProperty $aggregationType
