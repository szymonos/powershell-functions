<#
.Synopsis
Sample script for managing credentials using clixml and azure key vault
#>

# *Manage credentials using CliXml
# set credentials with username and password into variable
$user = 'CONTOSO\username'
$pass = ConvertTo-SecureString -String 'p@ssw0rd' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
# or
$user = 'CONTOSO\username'
$cred = Get-Credential $user -Message "Provide password for $user"

# export credentials to file
$cred | Export-Clixml -Path '.\.assets\export\cred.xml'
$cred | Export-Clixml -Path "$($HOME)\cred.xml"

# import credentials
$cred = Import-Clixml -Path '.\.assets\export\cred.xml'
$cred = Import-Clixml -Path "$($HOME)\cred.xml"

# get user and pass from credential file
Import-Clixml -Path "$($HOME)\cred.xml" | Select-Object -Property UserName, @{Name = 'Password'; Expression = { $_.GetNetworkCredential().Password } }
$cred.GetNetworkCredential().UserName
$cred.GetNetworkCredential().Password

# *Change AD passwwrd for a user
$domain = 'CONTOSO'
$identity = 'username'
$oldPass = ConvertTo-SecureString -AsPlainText 'old_password' -Force
$newPass = ConvertTo-SecureString -AsPlainText 'new_password' -Force
$oldCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$domain\$identity", $oldPass
Set-ADAccountPassword -Credential $oldcred -Identity $identity -OldPassword $oldPass -NewPassword $newPass
$newCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$domain\$identity", $newPass
$newCred | Export-Clixml -Path "$($HOME)\$identity.xml"

<# *Microsoft.PowerShell.SecretsManagement
.LINK
https://github.com/powershell/secretstore
https://github.com/powershell/secretmanagement
https://github.com/JustinGrote/SecretManagement.KeePass
https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-release-candidate-2/
https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/
.EXAMPLE
# *Update SecretStore module.
Uninstall-Module Microsoft.PowerShell.SecretManagement -Force
Uninstall-Module Microsoft.PowerShell.SecretStore -Force
# Restart your PowerShell session
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore
* set paswordless SecretStore
Set-SecretStoreConfiguration -Authentication None -Interaction None
Get-InstalledModule -Name Microsoft.PowerShell.SecretStore | Select-Object -Property Version, Name, Repository, InstalledLocation
#>
# register extension vaults
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Get-SecretVault
Unregister-SecretVault -Name SecretStore
Test-SecretVault

# Accessing secrets
Get-Secret
Get-SecretInfo -Vault SecretStore
Remove-Secret 'secretname' -Vault SecretStore

# manage SecretStore
Get-SecretStoreConfiguration
Set-SecretStoreConfiguration
Unlock-SecretStore
Set-SecretStorePassword
Reset-SecretStore

# *Store/Retrieve secrets.
$secretName = 'secretname'
$secretValue = 'passw0rd'
# store secret
Set-Secret $secretName -Secret $secretValue
# retrieve secret
Get-Secret $secretName -AsPlainText

# store PSCredential
$user = 'username'; $pass = ConvertTo-SecureString -String $secretValue -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Set-Secret $secretName -Secret $cred
# retreive pscredential
$cred = Get-Secret $secretName
$cred | Select-Object -Property UserName, @{Name = 'Password'; Expression = { $_.GetNetworkCredential().Password } }
$cred.GetNetworkCredential().Password

# add metadata to existing secret
Set-SecretInfo $secretName -Metadata @{ Name = Value }
(Get-SecretInfo $secretName -Vault SecretStore).Metadata

<# *Register KeePass Secret Management Extension.
Install-Module SecretManagement.Keepass
#>
Register-SecretVault -Name 'KeePass' -ModuleName 'SecretManagement.Keepass' -VaultParameters @{
    Path              = 'path/to/my/vault.kdbx'
    UseMasterPassword = $true
    KeyPath           = 'path/to/my/keyfile.key'
}
Test-SecretVault -Name 'KeePass'
Get-SecretInfo -Vault 'KeePass'
(Get-Secret -Name $secretName -Vault 'KeePass').GetNetworkCredential().Password

# *Register KeyVault Secret Management Extension.
$vaultName = 'kv-musci-weu'
$subID = (Get-AzSubscription -SubscriptionName 'SZYMONOS-MSDN').Id
Register-SecretVault -Module Az.KeyVault -Name AzKv -VaultParameters @{
    AZKVaultName   = $vaultName
    SubscriptionId = $subID
}
Test-SecretVault -Name 'AzKv'
Get-Secret -Name 'SecretName' -Vault 'AzKv' -AsPlainText
