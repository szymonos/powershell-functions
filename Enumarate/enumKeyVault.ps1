<#
[Windows.Forms.Clipboard]::SetText((Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name 'devops-kp').SecretValueText);Start-Sleep -s 15;[Windows.Forms.Clipboard]::Clear()
Get-AzKeyVault | Select-Object ResourceGroupName, VaultName
(Get-AzContext).Name
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
#>
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'
$keyVault = 'also-ecomvault-dev'; Connect-Subscription -Subscription 'ALSO IL DEV'
$keyVault = 'also-ecomvault-qa'; Connect-Subscription -Subscription 'ALSO IL QA'
$keyVault = 'also-ecomvault-prod'; Connect-Subscription -Subscription 'ALSO IL PROD'
$keyVault = 'also-devops-vault'; Connect-Subscription -Subscription 'ALSO IL DEV'
$keyVault = 'also-testers-vault'; Connect-Subscription -Subscription 'ALSO IL DEV'

Write-Output 'Getting list of Database users'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$tableSrv = Get-AzStorageTable -Name 'AzDbUsers' -Context $StorageContext
$dbUsers = Get-AzTableRows -Table $tableSrv | Where-Object { $_.authentication_type -eq 1 }

Write-Output 'Getting list of subscriptions'
$subscriptions = Get-AzSubscription | Sort-Object -Property Name | Select-Object -Property Name, Id

foreach ($sub in $subscriptions) {
    #$sub = $subscriptions[0]
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
    $vaultLoginsP = Get-AzKeyVaultSecret -VaultName $keyVault |
    Where-Object { $_.ContentType -eq 'sql-login' } |
    Select-Object -Property `
        Name, ContentType `
        , @{Name = 'Login'; Expression = { $_.Tags.login } }`
        , @{Name = 'KeyVault'; Expression = { $keyVault } }
    $subUsers = $dbUsers |
    Where-Object { $_.PartitionKey -eq $sub.Id } |
    Select-Object -Property name |
    Sort-Object -Property Name |
    Get-Unique -AsString
}

$kv = $vaultLogins | ForEach-Object {
    $_ | Where-Object { $_.Name -notin $vaultLoginsP.Name }
}
$vaultLogins | Export-Csv -Path '.\.assets\config\enumerateLogins.csv' -NoTypeInformation
$kv | Export-Csv -Path '.\.assets\config\enumerateLogins.csv' -NoTypeInformation



$dbUsers | Select-Object -Property name | Sort-Object -Property Name | Get-Unique -AsString
Get-Process | Sort-Object | Select-Object processname | Get-Unique -AsString

$secretName = 'alsodevopsstorage'
$secretValue = ConvertTo-SecureString 'password' -AsPlainText -Force
# Set secret with content type and tags
$contentType = 'service-principal'
$tags = @{ 'login' = 'login' }
#$tags = @{ 'login' = 'calineczka'; 'srv' = 'also-ufo3x-dev' }
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType $contentType -Tags $tags
# Set simple secret
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue
# Set secret with content type
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType $contentType

# Retreive secrets list
Get-AzKeyVaultSecret -VaultName $keyVault | Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } }, ContentType
Get-AzKeyVaultSecret -VaultName $keyVault | Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags } }, ContentType

# Retreive secret value
$secretName = 'calineczka'
Get-AzKeyVaultLoginPass -VaultName $keyVault -SecretName $secretName
Get-AzKeyVaultLoginPass -VaultName $keyVault -SecretName $secretName -PsCredential
(Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretName).SecretValueText

# Import secrets into Key Vault
$secrets = Import-Csv -Path 'C:\temp\enumerateLogins.csv'
$keyVault = 'also-ecomvault-prod'
foreach ($secret in $secrets) {
    $secretName = $secret.Name
    $secretValue = ConvertTo-SecureString $secret.Pass -AsPlainText -Force
    # Set secret with content type and tags
    $contentType = 'sql-login'
    $tags = @{ 'login' = $secret.Login; 'srv' = 'also-ecom' }
    #$tags = @{ 'login' = 'calineczka'; 'srv' = 'also-ufo3x-dev' }
    Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType $contentType -Tags $tags
}


$vaultsecrets = Get-AzKeyVaultSecret -VaultName $keyVault | Select-Object -Property VaultName, Name, Tags, ContentType
$secretsExpanded = foreach ($secret in $vaultsecrets) {
    $pass = (Get-AzKeyVaultSecret -VaultName $secret.VaultName -Name $secret.Name).SecretValueText
    $secret | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass
    foreach ($key in $secret.Tags.Keys) {
        $secret | Add-Member -MemberType NoteProperty -Name $key -Value $secret.Tags.$key
    }
    $secret | Select-Object -ExcludeProperty Tags
}
$secretsExpanded | Format-Table -AutoSize -Property Name, login, srv, ContentType, Password

$vaultsecrets = Get-AzKeyVaultSecret -VaultName $keyVault | ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $_.VaultName -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property VaultName, Name, Password

$bb = (Get-AzKeyVaultSecret -VaultName $keyVault)[1]
$bb | ForEach-Object {
    $tagNames = $_.Tags.Keys
    $tagNames
    foreach ($tag in $tagNames) {
        $_.Tag.$tag
    }
}
$bb.Tags.Keys
$bb.Tags | Get-Member

# Find secrets without srv tag
$fixSecrets = Get-AzKeyVaultSecret -VaultName $keyVault | Where-Object { $null -eq $_.Tags.srv } | ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $_.VaultName -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
}

# Reiterate secrets and add srv tag
foreach ($secret in $fixSecrets) {
    $secretName = $secret.Name
    $secretValue = ConvertTo-SecureString $secret.Password -AsPlainText -Force
    # Set secret with content type and tags
    $contentType = 'sql-login'
    $tags = @{ 'login' = $secret.Tags.login; 'srv' = 'also-ecom' }
    #$tags = @{ 'login' = 'calineczka'; 'srv' = 'also-ufo3x-dev' }
    Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType $contentType -Tags $tags
}
