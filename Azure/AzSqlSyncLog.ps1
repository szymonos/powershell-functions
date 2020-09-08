<#
.SYNOPSIS
Get SQL Sync logs from selected sync groups
.PARAMETER SyncGroups

.LINK
https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-monitor-sync
.EXAMPLE
Azure\AzSqlSyncLog.ps1
Azure\AzSqlSyncLog.ps1 -Table -HoursGet 1
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-PROD'
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-PROD' -Table
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-DEV' -Table
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-DEV'
Azure\AzSqlSyncLog.ps1 -SyncGroup 'AC-SyncGroup' -Table
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-PROD' -Table
Azure\AzSqlSyncLog.ps1 -SyncGroup 'LANG-SyncGroup-PROD' -Table -HoursGet 8
#>

param(
    $SyncGroup,
    [int]$HoursGet = 2,
    [switch]$Table
)

# common functions
. '.include\func_azcommon.ps1'

## Get CET for timezone conversion
$TZ = [TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time')

Write-Output 'Getting list of sql sync groups'
$syncGroups = Import-Csv -Path '.\.assets\config\Az\az_sqlsyncgrups.csv'

if ($SyncGroup) {
    $syncGroups = $syncGroups | Where-Object -Property SyncGroupName -eq $SyncGroup
}

$logs = @()
$startTime = [DateTime]::UtcNow.AddHours(-$HoursGet)
$endTime = [DateTime]::UtcNow
foreach ($syncGroup in $syncGroups) {
    #$syncGroup = $syncGroups[2]
    [System.Console]::WriteLine("`e[96m{0}`e[0m", $syncGroup.SyncGroupName)
    Connect-Subscription -Subscription $syncGroup.SubscriptionId | Out-Null
    $logs += Get-AzSqlSyncGroupLog -ResourceGroupName $syncGroup.ResourceGroupName `
        -ServerName $syncGroup.ServerName `
        -DatabaseName $syncGroup.DatabaseName `
        -SyncGroupName $syncGroup.SyncGroupName `
        -StartTime $startTime `
        -EndTime $endTime | Select-Object -Property LogLevel, Details `
        , @{Name = 'TimeStamp'; Expression = { [TimeZoneInfo]::ConvertTimeFromUtc($_.TimeStamp, $TZ) } } `
        , @{Name = 'SourceServer'; Expression = { $_.Source.Substring(0, $_.Source.IndexOf('.')) } } `
        , @{Name = 'Database'; Expression = { $_.Source.Substring($_.Source.IndexOf('/') + 1, $_.Source.Length - $_.Source.IndexOf('/') - 1) } } `
        , @{Name = 'SyncGroupName'; Expression = { $syncGroup.SyncGroupName } }
}

if ($Table) {
    $logs | Sort-Object -Property TimeStamp | Format-Table -Property SyncGroupName, TimeStamp, SourceServer, Database, LogLevel, Details -AutoSize
} else {
    $logs | Sort-Object -Property TimeStamp | Select-Object -Property SyncGroupName, TimeStamp, SourceServer, Database, LogLevel, Details
}
