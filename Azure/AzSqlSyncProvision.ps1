<#
.SYNOPSIS
Setting up Datasync on Azure Databases
.EXAMPLE
.test\AzDataSync.ps1
#>
# Include namespaces
using namespace Microsoft.Azure.Commands.Sql.DataSync.Model
using namespace System.Collections.Generic

# Include functions
. '.include\func_azcommon.ps1'

# hub database info
$subscriptionId = '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' # ALSO IL DEV
$resourceGroupName = 'Also-EcomSql-DEV'
$serverName = 'also-ecom-dev'

# sync database info
$syncDatabaseResourceGroupName = 'Also-EcomSql-DEV'
$syncDatabaseServerName = 'also-ecom-dev'
$syncDatabaseName = 'DATASYNC'

# sync group info
$conflictResolutionPolicy = 'HubWin' # can be HubWin or MemberWin
$intervalInSeconds = 300 # sync interval in seconds (must be no less than 300)

# member database info
$syncMemberName = 'DOCS-Database'
$memberServerName = 'also-ecom-dev.database.windows.net'
$memberDatabaseName = 'DOCS'
$memberDatabaseType = 'AzureSqlDatabase' # can be AzureSqlDatabase or SqlServerDatabase
$syncDirection = 'Onewayhubtomember' # can be Bidirectional, Onewaymembertohub, Onewayhubtomember

Select-AzSubscription -SubscriptionId $subscriptionId

# use if it's safe to show password in script, otherwise use PromptForCredential
# $user = "username"
# $password = ConvertTo-SecureString -String "password" -AsPlainText -Force
# $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $password
$keyVault = 'also-ecomvault-dev'
$secretName = 'dbsync-user'
$credential = Get-AzKeyVaultCredential -VaultName $keyVault -SecretName $secretName;


#$databaseName = 'AC'
$databaseName = 'LANG'
#$syncGroupName = 'AC-SyncGroup-Dev'
$syncGroupName = 'LANG-SyncGroup-Dev'

# create a new sync group
Write-Host "Creating Sync Group "$syncGroupName"..."
New-AzSqlSyncGroup -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -Name $syncGroupName `
    -SyncDatabaseName $syncDatabaseName -SyncDatabaseServerName $syncDatabaseServerName -SyncDatabaseResourceGroupName $syncDatabaseResourceGroupName `
    -ConflictResolutionPolicy $conflictResolutionPolicy -DatabaseCredential $credential

# add a new sync member
Write-Host "Adding member"$syncMemberName" to the sync group..."
$memberDatabases = 'DOCS', 'RMA', 'SCM', 'SOLP'
foreach ($memberDatabaseName in $memberDatabases) {
    $syncMemberName = "$memberDatabaseName-Database"
    New-AzSqlSyncMember -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -SyncGroupName $syncGroupName `
        -Name $syncMemberName -SyncDirection $syncDirection -MemberDatabaseType $memberDatabaseType -MemberServerName $memberServerName `
        -MemberDatabaseName $memberDatabaseName -MemberDatabaseCredential $credential
}

# refresh database schema from hub database, specify the -SyncMemberName parameter if you want to refresh schema from the member database
Write-Host "Refreshing database schema from hub database..."
$startTime = Get-Date
Update-AzSqlSyncSchema -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -SyncGroupName $syncGroupName

# waiting for successful refresh
$startTime = $startTime.ToUniversalTime()
$timer = 0
$timeout = 90

# check the log and see if refresh has gone through
Write-Host "Check for successful refresh..."
$isSucceeded = $false
while ($isSucceeded -eq $false) {
    Start-Sleep -s 10
    $timer = $timer + 10
    $details = Get-AzSqlSyncSchema -SyncGroupName $syncGroupName -ServerName $serverName -DatabaseName $databaseName -ResourceGroupName $resourceGroupName
    if ($details.LastUpdateTime -gt $startTime) {
        Write-Host "Refresh was successful"
        $isSucceeded = $true
    }
    if ($timer -eq $timeout) {
        Write-Host "Refresh timed out"
        break;
    }
}

if ($isSucceeded) {
    # enable scheduled sync
    Write-Host "Enable the scheduled sync with 300 seconds interval..."
    Update-AzSqlSyncGroup  -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName `
        -Name $syncGroupName -IntervalInSeconds $intervalInSeconds
}
else {
    # output all log if sync doesn't succeed in 300 seconds
    $syncLogEndTime = Get-Date
    $syncLogList = Get-AzSqlSyncGroupLog -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName `
        -SyncGroupName $syncGroupName -StartTime $syncLogStartTime.ToUniversalTime() -EndTime $syncLogEndTime.ToUniversalTime()

    if ($synclogList.Length -gt 0) {
        foreach ($syncLog in $syncLogList) {
            Write-Host $syncLog.TimeStamp : $syncLog.Details
        }
    }
}

# Check SQL Sync properties
Get-AzSqlSyncGroup -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -SyncGroupName $syncGroupName | `
    Select-Object -Property SyncGroupName, IntervalInSeconds, HubDatabaseUserName, ConflictResolutionPolicy, SyncState, LastSyncTime
Get-AzSqlSyncGroup -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName 'AC' | `
    Select-Object -Property SyncGroupName, IntervalInSeconds, HubDatabaseUserName, ConflictResolutionPolicy, SyncState, LastSyncTime
