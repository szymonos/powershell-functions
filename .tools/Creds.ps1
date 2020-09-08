<#
.Synopsis
Sample script for managing credentials using clixml and azure key vault
#>

<### Manage credentials using CliXml ###>
## Set credentials with username and password into variable
$user = 'CONTOSO\username'
$pass = ConvertTo-SecureString -String 'p@ssw0rd' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
# or
$user = 'CONTOSO\username'
$cred = Get-Credential $user -Message "Provide password for $user"

## Export credentials to file
$cred | Export-CliXml -Path '.\.assets\export\cred.xml'
$cred | Export-CliXml -Path "$($env:USERPROFILE)\cred.xml"

## Import credentials
$cred = Import-CliXml -Path '.\.assets\export\cred.xml'
$cred = Import-CliXml -Path "$($env:USERPROFILE)\cred.xml"

## Get user and pass from credential file
Import-CliXml -Path "$($env:USERPROFILE)\cred.xml" | Select-Object -Property UserName, @{Name = 'Password'; Expression = {$_.GetNetworkCredential().Password}}
$cred.GetNetworkCredential().UserName
$cred.GetNetworkCredential().Password

<### Manage credentials using Azure Key Vault ###>
$keyVault = 'ContosoKeyVault'
$secretName = 'ExampleSecret'
$secretValue = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
# Set simple secret
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue
# Set secret with content type
$contentType = 'sql-login'
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType
# Set secret with content type and tags
$tags = @{ 'login' = 'sqllogin'; 'srv' = 'srvname' }
Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secretValue -ContentType $contentType -Tags $tags

# Retreive secrets list
Get-AzKeyVaultSecret -VaultName $keyVault | Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } }, ContentType
# Retreive secret value
(Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretName).SecretValueText

<### Change AD passwwrd for a user ###>
$domain = 'CONTOSO'
$identity = 'username'
$oldPass = ConvertTo-SecureString -AsPlainText 'old_password' -Force
$newPass = ConvertTo-SecureString -AsPlainText 'new_password' -Force
$oldCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$domain\$identity", $oldPass
Set-ADAccountPassword -Credential $oldcred -Identity $identity -OldPassword $oldPass -NewPassword $newPass
$newCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$domain\$identity", $newPass
$newCred | Export-CliXml -Path "$($env:USERPROFILE)\$identity.xml"


<### Microsoft.PowerShell.SecretsManagement ###
Install-Module Microsoft.PowerShell.SecretManagement -AllowPrerelease
Import-Module Microsoft.PowerShell.SecretsManagement
#>
# Registering extension vaults
Register-SecretVault
Get-SecretVault
Unregister-SecretVault
Test-SecretVault # new cmdlet in this release

# Accessing secrets
Set-Secret
Get-Secret
Get-SecretInfo
Remove-Secret 'secretname' -Vault BuiltInLocalVault

Get-Help Get-Secret

# Store PSCredential
$secret = 'secretname'
$user = 'username'
$pass = ConvertTo-SecureString -String 'Passw0rd' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Set-Secret $secret -Secret $cred
# Retreive pscredential
$cred = Get-Secret $secret
Get-Secret 'secretname' | Select-Object -Property UserName, @{Name = 'Password'; Expression = {$_.GetNetworkCredential().Password}}

# Store SecureString
Set-Secret $secret -SecureStringSecret $pass
# Retreive secure string
Get-Secret $secret -AsPlainText
