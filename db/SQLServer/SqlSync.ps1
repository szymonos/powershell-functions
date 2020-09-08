<#
.Description
Check DataSync status
.Example
db\SQLServer\SqlSync.ps1
#>
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

Write-Output 'Getting list of SQL Servers'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$table = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext -ErrorAction SilentlyContinue
$sqlServers = Get-AzTableRows -Table $table

#$subscriptions = Get-AzSubscription | Sort-Object -Property Name | Select-Object -Property Id, Name
$subscriptions = Get-AzSubscription | Where-Object { $_.Id -eq '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' } | Sort-Object -Property Name | Select-Object -Property Id, Name

Write-Output 'Checking sync groups in subscription:'
$syncGroups = @()
foreach ($sub in $subscriptions) {
    Write-Host ("`n" + $sub.Name) -ForegroundColor Magenta
    Connect-Subscription -Subscription $sub.Id | Out-Null
    $servers = $sqlServers | Where-Object { $_.PartitionKey -eq $sub.Id }
    Write-Output 'Checking sync groups on:'
    foreach ($srv in $servers) {
        Write-Output ('Server: ' + $srv.ServerName + ', database:')
        $dbList = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |`
            Where-Object { $_.DatabaseName -ne 'master' } |`
            Select-Object -Property ResourceGroupName, ServerName, DatabaseName
        foreach ($db in $dbList) {
            Write-Output (' - ' + $db.DatabaseName)
            $syncGroups += Get-AzSqlSyncGroup -ResourceGroupName $db.ResourceGroupName -ServerName $db.ServerName -DatabaseName $db.DatabaseName |`
                Select-Object -Property ResourceGroupName, ServerName, DatabaseName
        }
    }
}

$groupsCnt = ($syncGroups | Measure-Object).Count
Write-Output "`nFound $groupsCnt database sync group(s)"
foreach ($sg in $syncGroups) {
    Get-AzSqlSyncGroup -ResourceGroupName $sg.ResourceGroupName -ServerName $sg.ServerName -DatabaseName $sg.DatabaseName | Select-Object -Property ServerName, DatabaseName, SyncGroupName, ConflictResolutionPolicy, SyncState
}
