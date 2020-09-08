<#
.Synopsis
.Example
Enumarate\enumAzDatabases.ps1
#>
# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

# Get list of subscriptions servers form Azure storage table
Write-Output 'Getting Azure storage table context'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

Write-Output 'Getting list of subscriptions'
$subscriptions = Get-AzSubscription | Where-Object -Property Id -ne '02c57fdb-6ccc-4892-950d-c008cbb24d5d' | Sort-Object -Property Name | Select-Object -Property Id, Name

Write-Output 'Getting list of SQL servers'
$tableSrv = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext
$sqlServers = Get-AzTableRows -Table $tableSrv | Sort-Object -Property PartitionKey

# Get context of table where databases will be stored to
$table = Select-AzTable -TableName 'AzDatabases' -StorageContext $StorageContext

<#
$sqlServers | Sort-Object -Property RowKey | Format-Table -AutoSize -Property RowKey, ServerName, PartitionKey
$srv = $sqlServers | Where-Object { $_.RowKey -eq 7 }; Connect-Subscription -Subscription $srv.partitionKey
#>
#$dbProps = 'ResourceGroupName','ServerName','DatabaseName','Location','Edition','CollationName','MaxSizeBytes','Status','CreationDate','EarliestRestoreDate','ReadScale','ZoneRedundant','Capacity','MinimumCapacity','SkuName','LicenseType','AutoPauseDelayInMinutes'

Remove-AzTableRows -Table $table
foreach ($sub in $subscriptions) {
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $subServers = $sqlServers | Where-Object { $_.PartitionKey -eq $sub.Id }

    Write-Output 'Enumerating databases on server:'
    foreach ($srv in $subServers) {
        Write-Output (' - ' + $srv.ServerName)
        Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |
            Where-Object { $_.DatabaseName -ne 'master' } |
            ForEach-Object {
                $prop = @{
                    Subscription            = $sub.Name
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
                Add-AzTableRow -Table $table -PartitionKey $sub.Id -RowKey $_.DatabaseId -Property $prop
            }
        Get-AzSqlElasticPool -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | ForEach-Object {
            $prop = @{
                Subscription            = $sub.Name
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
            Add-AzTableRow -Table $table -PartitionKey $sub.Id -RowKey (New-Guid).Guid -Property $prop
        }
    }
}
