<#
.SYNOPSIS
Manage Azure Storage Blobs
.DESCRIPTION
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.LINK
https://docs.microsoft.com/en-us/powershell/module/Az.Storage
.EXAMPLE
Azure\AzStorageBlob.ps1
Azure\AzStorageBlob.ps1 -CleanXE -RetentionDays 14
#>

param (
    [switch]$CleanBlobs,
    [int]$RetentionDays = 21
)

$container = 'extended-events'
$container = 'bacpacs'

# storage context
$storageAccountName = 'alsoilprodsqlstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-ecomvault-prod' -Name $storageAccountName).SecretValueText
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

Get-AzStorageContainer -Context $storageContext
Get-AzStorageBlob -Container $container -Context $storageContext -Blob '*ac_*'

if ($CleanXE) {
    # Remove all blobs elder than 3 weeks
    Get-AzStorageBlob -Container $container -Context $storageContext | `
        Where-Object -Property LastModified -lt (Get-Date).AddDays(-$RetentionDays) | `
        Remove-AzStorageBlob
}
