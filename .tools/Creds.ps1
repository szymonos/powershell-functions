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
$cred | Export-CliXml -Path '.\.assets\export\cred.xml'
$cred | Export-CliXml -Path "$($env:USERPROFILE)\cred.xml"

# import credentials
$cred = Import-CliXml -Path '.\.assets\export\cred.xml'
$cred = Import-CliXml -Path "$($env:USERPROFILE)\cred.xml"

# get user and pass from credential file
Import-CliXml -Path "$($env:USERPROFILE)\cred.xml" | Select-Object -Property UserName, @{Name = 'Password'; Expression = {$_.GetNetworkCredential().Password}}
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
$newCred | Export-CliXml -Path "$($env:USERPROFILE)\$identity.xml"

<# *Microsoft.PowerShell.SecretsManagement
.LINK
https://github.com/powershell/secretmanagement
https://devblogs.microsoft.com/powershell/secretmanagement-preview-3/
https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-updates/
.EXAMPLE
Install-Module -Name Microsoft.PowerShell.SecretManagement -Scope CurrentUser -AllowPrerelease -Force
Install-Module -Name Microsoft.PowerShell.SecretStore -Scope CurrentUser -AllowPrerelease -Force
Reset-SecretStore
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

Get-InstalledModule -Name Microsoft.PowerShell.SecretManagement | Select-Object *
#>
# register extension vaults
Register-SecretVault -Name SecretStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault
Get-SecretVault
Unregister-SecretVault
Test-SecretVault # new cmdlet in this release

# Accessing secrets
Set-Secret
Get-Secret
Get-SecretInfo
Remove-Secret 'secretname' -Vault BuiltInLocalVault

Get-Help Get-Secret

# store PSCredential
$secret = 'secretname'
$user = 'username'
$pass = ConvertTo-SecureString -String 'Passw0rd' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $pass
Set-Secret $secret -Secret $cred
# retreive pscredential
$cred = Get-Secret $secret
Get-Secret 'secretname' | Select-Object -Property UserName, @{Name = 'Password'; Expression = {$_.GetNetworkCredential().Password}}

# store SecureString
Set-Secret $secret -SecureStringSecret $pass
# retreive secure string
Get-Secret $secret -AsPlainText
