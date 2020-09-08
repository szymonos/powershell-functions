<#
.Synopsis
.Example
Enumarate\enumAzSqlServers.ps1
Enumarate\enumAzSqlServers.ps1 -OutTerminal
#>

param (
    [switch]$OutTerminal
)
. '.\.include\func_azcommon.ps1'

# Enumerate Azure subscriptions
$subscriptions = Get-AzSubscription | Where-Object -Property Id -ne '02c57fdb-6ccc-4892-950d-c008cbb24d5d' | Sort-Object -Property Name | Select-Object -Property Id, Name

Write-Output ('Enumarating servers in subscription:')

# Enumerate SQL servers in all subscriptions
$sqlServers = @(); $i = 0
foreach ($sub in $subscriptions) {
    Write-Output (' - ' + $sub.Name)
    Connect-Subscription -Subscription $sub.Id | Out-Null
    $sqlServers += Get-AzSqlServer |
        Select-Object -Property `
            ServerName, ResourceGroupName, Location, ServerVersion, SqlAdministratorLogin `
            , @{ Name = 'FQDN'; Expression = { $_.FullyQualifiedDomainName } } `
            , @{ Name = 'SubscriptionId'; Expression = { $sub.Id } } `
            , @{ Name = 'Subscription'; Expression = { $sub.Name } } |
        ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru
            $i++
        }
}

if ($OutTerminal) {
    # Print results on terminal
    $sqlServers | Format-Table -AutoSize -Property Id, ServerName, FQDN, ResourceGroupName, Subscription, Location, SqlAdministratorLogin
}
else {
    # Define the storage account and context for Azure storage table
    . '.\.include\func_azstorage.ps1'
    Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
    $StorageAccountName = 'alsodevopsstorage'
    $storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
    $StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    $table = Select-AzTable -TableName 'AzSqlServers' -StorageContext $StorageContext

    # Clear target storage table
    Remove-AzTableRows -Table $table

    # Enumerate object properties
    $properties = ($sqlServers | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -notin 'Id', 'SubscriptionId' }

    # Set properties for Add-AzTableRow function
    foreach ($srv in $sqlServers) {
        $partitionKey = $srv.SubscriptionId
        $rowKey = $srv.Id
        $prop = @{ };
        foreach ($p in $properties) {
            $prop.Add($p, $srv.($p))
        }
        Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
    }
}
