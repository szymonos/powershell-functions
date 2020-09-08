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

## Resource parameters
$resourceGroup = 'ALSO-Caches-PROD'
$cacheName = 'also-interlinkcache-prod'

$cacheId = Get-AzRedisCache -ResourceGroupName $resourceGroup -Name $cacheName | Select-Object -Property Id, Size
Get-AzMetric -ResourceId $cacheId.Id -MetricName 'usedmemory' -StartTime (Get-Date).AddMinutes(-1) | Select-Object @{Name = 'UsedGB'; Expression = { [math]::Round(($_.Data.Maximum / 1GB), 2) } }

Get-AzRedisCache -ResourceGroupName $resourceGroup -Name $cacheName | Select-Object -Property * -ExcludeProperty Id, SubnetId, StaticIP, TenantSettings, ShardCount, Tag, Zone

$myLoc = Get-Location
Set-Location @myLoc
Set-Location 'C:\Program Files\Redis'
.\redis-cli.exe -h also-interlinkcache-prod.redis.cache.windows.net -p 6380 -a key=
