<#
.Synopsis
.Example
Enumarate\enumAzSubscriptions.ps1
Enumarate\enumAzSubscriptions.ps1 -OutTerminal
#>

param (
    [switch]$OutTerminal = $false
)
. '.\.include\func_azcommon.ps1'

# Enumerate Azure subscriptions
$subscriptions = Get-AzSubscription | Where-Object -Property Id -ne '02c57fdb-6ccc-4892-950d-c008cbb24d5d' | Sort-Object -Property Name | Select-Object Name, Id, TenantId, State
Write-Output ('Enumarating servers in subscription:')

if ($OutTerminal) {
    # Print results on terminal
    $subscriptions | Format-Table -AutoSize -Property Name, Id, State
}
else {
    # Define the storage account and context for Azure storage table
    . '.\.include\func_azstorage.ps1'
    Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
    $StorageAccountName = 'alsodevopsstorage'
    $storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
    $StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    $table = Select-AzTable -TableName 'AzSubscriptions' -StorageContext $StorageContext

    # Clear target storage table
    Remove-AzTableRows -Table $table

    # Enumerate object properties
    $properties = ($subscriptions | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -notin 'Id', 'TenantId' }

    # Set properties for Add-AzTableRow function
    foreach ($sub in $subscriptions) {
        $partitionKey = $sub.TenantId
        $rowKey = $sub.Id
        $prop = @{ };
        foreach ($p in $properties) {
            $prop.Add($p, $sub.($p))
        }
        Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
    }
}
