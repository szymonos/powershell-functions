<#
.Synopsis
.Example
Enumarate\enumAzDatabasesCsv.ps1
#>
# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

Write-Output 'Getting list of subscriptions'
$subscriptions = Import-Csv -Path '.\.assets\config\Az\az_subscriptions.csv'

Write-Output 'Getting list of SQL servers'
$sqlServers = Import-Csv -Path '.\.assets\config\Az\az_sqlservers.csv'

<#
$sqlServers | Sort-Object -Property RowKey | Format-Table -AutoSize -Property RowKey, ServerName, PartitionKey
$srv = $sqlServers | Where-Object { $_.RowKey -eq 7 }; Connect-Subscription -Subscription $srv.partitionKey
#>
#$dbProps = 'ResourceGroupName','ServerName','DatabaseName','Location','Edition','CollationName','MaxSizeBytes','Status','CreationDate','EarliestRestoreDate','ReadScale','ZoneRedundant','Capacity','MinimumCapacity','SkuName','LicenseType','AutoPauseDelayInMinutes'

$dbs = @()
foreach ($sub in $subscriptions) {
    #$sub = $subscriptions[0]
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $subServers = $sqlServers | Where-Object { $_.SubscriptionId -eq $sub.Id }

    Write-Output 'Enumerating databases on server:'
    foreach ($srv in $subServers) {
        #$srv = $subServers[0]
        Write-Output (' - ' + $srv.ServerName)
        $dbs += Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |
        Where-Object { $_.DatabaseName -ne 'master' } |
        ForEach-Object {
            $prop = @{
                Subscription            = $sub.Name
                SubscriptionId          = $sub.Id
                ResourceGroupName       = $_.ResourceGroupName
                ServerName              = $_.ServerName
                Name                    = $_.DatabaseName
                Service                 = 'databases'
                Location                = $_.Location
                Edition                 = $_.Edition
                CollationName           = $_.CollationName
                MaxSizeBytes            = $_.MaxSizeBytes
                Status                  = $_.Status
                CreationDate            = $_.CreationDate
                EarliestRestoreDate     = $_.EarliestRestoreDate
                ZoneRedundant           = $_.ZoneRedundant
                Capacity                = $_.Capacity
                MinimumCapacity         = $_.MinimumCapacity
                SkuName                 = $_.SkuName
                ElasticPoolName         = $_.ElasticPoolName
                LicenseType             = $_.LicenseType
                AutoPauseDelayInMinutes = $_.AutoPauseDelayInMinutes
            }
            [PSCustomObject]$prop
        }
        $dbs += Get-AzSqlElasticPool -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | ForEach-Object {
            $prop = @{
                Subscription            = $sub.Name
                SubscriptionId          = $sub.Id
                ResourceGroupName       = $_.ResourceGroupName
                ServerName              = $_.ServerName
                Name                    = $_.ElasticPoolName
                Service                 = 'elasticpools'
                Location                = $_.Location
                Edition                 = $_.Edition
                CollationName           = $_.CollationName
                MaxSizeBytes            = $_.MaxSizeBytes
                Status                  = $_.State
                CreationDate            = $_.CreationDate
                EarliestRestoreDate     = $_.EarliestRestoreDate
                ZoneRedundant           = $_.ZoneRedundant
                Capacity                = $_.Capacity
                MinimumCapacity         = $_.MinimumCapacity
                SkuName                 = $_.SkuName
                ElasticPoolName         = $_.ElasticPoolName
                LicenseType             = $_.LicenseType
                AutoPauseDelayInMinutes = $_.AutoPauseDelayInMinutes
            }
            [PSCustomObject]$prop
        }
    }
    $dbs | Export-Csv -Path '.\.assets\config\Az\az_sqldatabases.csv' -NoTypeInformation -Encoding utf8
}
