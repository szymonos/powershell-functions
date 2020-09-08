function Select-AzTable {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)][string]$TableName,
        [Parameter(Mandatory = $true)][psobject]$StorageContext
    )
    $table = Get-AzStorageTable -Name $TableName -Context $StorageContext -ErrorAction SilentlyContinue
    if ($null -eq $table) {
        $table = New-AzStorageTable –Name $TableName -Context $StorageContext
    }
    return $table
}
function Add-AzTableRow {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]$Table,
        [Parameter(Mandatory = $true)][String]$PartitionKey,
        [Parameter(Mandatory = $true)][String]$RowKey,
        [Parameter(Mandatory = $false)][hashtable]$Property,
        [Switch]$UpdateExisting
    )
    # Creates the table entity with mandatory PartitionKey and RowKey arguments
    $entity = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.DynamicTableEntity' -ArgumentList $PartitionKey, $RowKey
    # Adding the additional columns to the table entity
    foreach ($prop in $Property.Keys) {
        if ($prop -ne 'TableTimestamp' -and ![string]::IsNullOrEmpty($Property.Item($prop))) {
            $entity.Properties.Add($prop, $Property.Item($prop))
        }
    }

    if ($UpdateExisting) {
        $Table.CloudTable.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($entity)) | Out-Null
    }
    else {
        $Table.CloudTable.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($entity)) | Out-Null
    }
}
function Get-AzTableRows {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]$Table
    )

    # Query Table
    $query = New-Object Microsoft.Azure.Cosmos.Table.TableQuery

    $token = $null
    do {
        $result = $table.CloudTable.ExecuteQuerySegmentedAsync($query, $token)
        $token = $result.ContinuationToken;
    } while ($null -ne $token)
    $azTableResult = $result.Result.Results
    $AzTable = @()
    foreach ($res in $azTableResult) {
        $azProp = @{
            PartitionKey = $res.PartitionKey;
            RowKey       = $res.RowKey
        }
        $Property = $res.Properties | Where-Object { $_.Keys -notin 'TableTimestamp', 'PartitionKey', 'RowKey' }
        foreach ($prop in $Property.Keys) {
            $azProp.Add($prop, $Property.Item($prop).PropertyAsObject)
        }
        $AzTable += [pscustomobject]$azProp
    }
    return $AzTable
}
function Remove-AzTableRows {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]$Table,
        [Parameter(Mandatory = $false)][string]$PartitionKey
    )

    # Query Table
    $query = New-Object Microsoft.Azure.Cosmos.Table.TableQuery
    ## Define columns to select.
    $list = New-Object System.Collections.Generic.List[string]
    $list.Add('RowKey')
    $list.Add('PartitionKey')
    $query.SelectColumns = $list
    if (![string]::IsNullOrEmpty($PartitionKey)) {
        [string]$Filter = "(PartitionKey eq '$($PartitionKey)')"
        $query.FilterString = $Filter
    }

    $token = $null
    do {
        $result = $table.CloudTable.ExecuteQuerySegmentedAsync($query, $token)
        $token = $result.ContinuationToken;
    } while ($null -ne $token)

    # Converting DynamicTableEntity to TableEntity for deletion
    $entityToDelete = New-Object -TypeName 'Microsoft.Azure.Cosmos.Table.TableEntity'
    foreach ($itemToDelete in $result.Result.Results) {
        $entityToDelete.ETag = $itemToDelete.Etag
        $entityToDelete.PartitionKey = $itemToDelete.PartitionKey
        $entityToDelete.RowKey = $itemToDelete.RowKey

        if ($null -ne $entityToDelete) {
            $Table.CloudTable.ExecuteAsync([Microsoft.Azure.Cosmos.Table.TableOperation]::Delete($entityToDelete)) | Out-Null
        }
    }
}
