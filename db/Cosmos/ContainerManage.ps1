<#
.Synopsis
.Description
https://docs.microsoft.com/en-us/azure/cosmos-db/manage-with-powershell#create-container

(Get-AzContext).Name
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
CosmosDB\ContainerManage.ps1
#>

# List all Azure Cosmos containers in a database
$resourceGroupName = 'Also-IL-DEV'
$accountName = 'also-xlink-cosomos-dev'
$databaseName = 'XLINK'
$containerSettings = 'Microsoft.DocumentDb/databaseAccounts/apis/databases/containers/settings'
$apiVersion = '2015-04-08'

# create context to work with collections in specified database
$cosmosDbContext = New-CosmosDbContext -ResourceGroupName $resourceGroupName -Account $accountName -Database $databaseName -MasterKeyType 'SecondaryMasterKey'

$excludedCollections = '_autoscale-metadata', 'EmailsLog'
## List all Collections
$containers = Get-CosmosDbCollection -Context $cosmosDbContext |`
    Where-Object -Property Id -NotIn $excludedCollections |`
    Select-Object -Property id `
    , @{Name = 'partitionKey'; Expression = { [string]$_.partitionKey.paths } } `
    , @{Name = 'uniqueKeys'; Expression = { $_.uniqueKeyPolicy.uniqueKeys.paths } } `
    , @{Name = 'indexingPolicy'; Expression = { $_.indexingPolicy } } `
    , @{Name = 'conflictResolutionPolicy'; Expression = { $_.conflictResolutionPolicy } }

# Get containers count
[PSCustomObject]@{ContainersCount = $containers.Count}

# Get throughput for all containters
$containers | ForEach-Object {
    $containerThroughputResourceName = $accountName + '/sql/' + $databaseName + "/" + $_.id + '/throughput'
    $throughput = Get-AzResource -ResourceType $containerSettings `
        -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
        -Name $containerThroughputResourceName | Select-Object -ExpandProperty Properties
    $_ | Add-Member -MemberType NoteProperty -Name 'throughput' -Value $throughput.throughput
}
$containers | Select-Object -Property id, throughput, partitionKey, uniqueKeys
# Get throughput on the database level
$dbSetting = 'Microsoft.DocumentDb/databaseAccounts/apis/databases/settings'
$dbThroughputResourceName = $accountName + '/sql/' + $databaseName + '/throughput'
Get-AzResource -ResourceType $dbSetting -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $dbThroughputResourceName | Select-Object -ExpandProperty Properties

# Specify new database
$resourceGroupName = 'Also-CosmosDB-PROD'
$accountName = 'also-xlink-cosmos'
$DbNew = 'XLINK'
$cosmosDbNewContext = New-CosmosDbContext -ResourceGroupName $resourceGroupName -Account $accountName -Database $DbNew -MasterKeyType 'SecondaryMasterKey'

# Recreate containers in new database
foreach ($container in $containers) {
    #$container = $containers | Where-Object { $_.id -eq 'V3WHRmaSN' }
    if ($null -eq $container.uniqueKeys) {
        New-CosmosDbCollection -Context $cosmosDbNewContext -Id $container.id -PartitionKey $container.partitionKey
    }
    else {
        $uniqueKey = New-CosmosDbCollectionUniqueKey -Path $container.uniqueKeys
        $uniqueKeyPolicy = New-CosmosDbCollectionUniqueKeyPolicy -UniqueKey $uniqueKey
        New-CosmosDbCollection -Context $cosmosDbNewContext -Id $container.id -PartitionKey $container.partitionKey -UniqueKeyPolicy $uniqueKeyPolicy
    }
}

$containersNew = Get-CosmosDbCollection -Context $cosmosDbNewContext | `
    Sort-Object -Property id | `
    Select-Object -Property id `
    , @{Name = 'partitionKey'; Expression = { [string]$_.partitionKey.paths } } `
    , @{Name = 'uniqueKeys'; Expression = { $_.uniqueKeyPolicy.uniqueKeys.paths } }
$containersNew | Sort-Object -Property id | Select-Object -Property id, partitionKey, uniqueKeys
$containers | Sort-Object -Property id | Select-Object -Property id, partitionKey, uniqueKeys

## Delete collection
Get-CosmosDbCollection -Context $cosmosDbContext | Select-Object Id

#Remove-CosmosDbCollection -Context $cosmosDb2Context -Id $colName

<# Recreate database Tools

$databaseName = 'Tools'
$cosmosDbContext = New-CosmosDbContext -ResourceGroupName $resourceGroupName -Account $accountName -Database $databaseName -MasterKeyType 'SecondaryMasterKey'

Remove-CosmosDbDatabase -Context $cosmosDbContext -Id $databaseName

New-CosmosDbDatabase -Context $cosmosDbContext -Id $databaseName
New-CosmosDbCollection -Context $cosmosDbContext -Id $databaseName -PartitionKey '/serviceName'

Get-CosmosDbDatabase -Context $cosmosDbContext

Get-CosmosDbCollection -Context $cosmosDbContext | `
    Sort-Object -Property id | `
    Select-Object -Property id `
    , @{Name = 'partitionKey'; Expression = { [string]$_.partitionKey.paths } } `
    , @{Name = 'uniqueKeys'; Expression = { $_.uniqueKeyPolicy.uniqueKeys.paths } }
#>

# List and Get operations for Cosmos SQL API
