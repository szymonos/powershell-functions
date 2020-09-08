<#
Get-AzKeyVault | Select-Object ResourceGroupName, VaultName
(Get-AzContext).Name
#>

$keyVault = 'also-ecomvault-dev';. '.include\func_azcommon.ps1'; Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3'     # ALSO IL DEV
$keyVault = 'also-testers-vault';. '.include\func_azcommon.ps1'; Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3'     # ALSO IL DEV
$keyVault = 'also-devsvault-dev';. '.include\func_azcommon.ps1'; Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3'     # ALSO IL DEV

# Retreive secrets list
Get-AzKeyVaultSecret -VaultName $keyVault | Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } }, ContentType
$kvs = Get-AzKeyVaultAllLogins -VaultName $keyVault; $kvs | Format-Table -AutoSize

# Get specific secret
$secretName = ('user' -replace ('_', '-')) -replace ('\.', '-'); Get-AzKeyVaultLoginPass -VaultName $keyVault -SecretName $secretName
