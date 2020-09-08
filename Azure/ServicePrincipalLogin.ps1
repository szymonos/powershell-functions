<#
.Synopsis
Managing Azure service principals
.Description
https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps
https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps
#>

# Create new Azure service principal
$svcPrincipalName = 'ServicePrincipalName'
$sp = New-AzADServicePrincipal -DisplayName $svcPrincipalName
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$svcPrincipalAppId = $sp.ApplicationId.Guid

# Add service principal to Azure KeyVault
$keyVault = 'KeyVaultName'
$secretValue = ConvertTo-SecureString $UnsecureSecret -AsPlainText -Force
$contentType = 'service-principal'
$tags = @{ 'login' = $svcPrincipalAppId }
Set-AzKeyVaultSecret -VaultName $keyVault -Name $svcPrincipalName -SecretValue $secretValue -ContentType $contentType -Tags $tags

# Create self signed certificate
openssl req -x509 -newkey rsa:4096 -keyout "$svcPrincipalName-key.pem" -out "$svcPrincipalName.pem" -days 365

# Retreive service principal credentials from Azure Key Vault
$secretName = (Get-AzKeyVaultSecret -VaultName $keyVault | Where-Object { $_.ContentType -eq 'service-principal' }).Name
$cred = Get-AzKeyVaultLoginPass -VaultName $keyVault -SecretName $secretName -PsCredential

# Sign in with a service principal
$tenantId = (Get-AzContext).Tenant.Id
Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $tenantId

# Get an existing service principal
Get-AzADServicePrincipal -ObjectId 'bf2ced3e-997d-4b1f-a814-4e16f8250773'
Get-AzADServicePrincipal -DisplayName $svcPrincipalName
Get-AzADServicePrincipal -DisplayNameBeginsWith 'interlink'

$svcPrincipal = Get-AzADServicePrincipal -DisplayName $svcPrincipalName
$svcPrincipal = Get-AzADServicePrincipal -ApplicationId '035a7ea7-a774-4b9b-97ca-e08e87303f29'
$svcPrincipalName = $svcPrincipal.DisplayName
$svcPrincipalAppId = $svcPrincipal.ApplicationId.Guid
$svcPrincipalId = $svcPrincipal.Id

# Manage service principal roles
Get-AzRoleAssignment -ObjectId $svcPrincipalId

New-AzRoleAssignment -ObjectId $svcPrincipalId -RoleDefinitionName 'Reader'
New-AzRoleAssignment -ObjectId $svcPrincipalId -RoleDefinitionName 'Contributor'
Remove-AzRoleAssignment -ObjectId $svcPrincipalId -RoleDefinitionName 'Reader'
Remove-AzRoleAssignment -ObjectId $svcPrincipalId -RoleDefinitionName 'Contributor'

# Reset credentials
Remove-AzADServicePrincipalCredential -DisplayName $svcPrincipalName
$newCredential = New-AzADSpCredential -ServicePrincipalName $svcPrincipalAppId
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newCredential.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Remove service principal
Remove-AzADServicePrincipal -ObjectId $svcPrincipalId

# Sign out from Azure
Disconnect-AzAccount
