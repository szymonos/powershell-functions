<#
.Synopsis
.Example
Enumarate\enumAzSqlSyncGroupsCsv.ps1
#>
# Include functions
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

$syncGroups = @()
foreach ($sub in $subscriptions) {
    #$sub = $subscriptions[0]
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $subServers = $sqlServers | Where-Object { $_.SubscriptionId -eq $sub.Id }

    Write-Output 'Enumerating databases on server:'
    foreach ($srv in $subServers) {
        #$srv = $subServers[1]
        [System.Console]::WriteLine("`e[96m{0}`e[0m", $srv.ServerName)
        $dbs = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | `
            Where-Object -Property DatabaseName -ne 'master' | `
            Select-Object -Property DatabaseName
        foreach ($db in $dbs) {
            Write-Output (' - ' + $db.DatabaseName)
            $syncGroups += Get-AzSqlSyncGroup -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DatabaseName $db.DatabaseName |`
                Select-Object -Property ResourceGroupName, ServerName, DatabaseName, SyncGroupName, @{Name = 'SubscriptionId'; Expression = { $sub.Id } }
        }
    }
}
$syncGroups | Export-Csv -Path '.\.assets\config\Az\az_sqlsyncgrups.csv' -NoTypeInformation -Encoding utf8
