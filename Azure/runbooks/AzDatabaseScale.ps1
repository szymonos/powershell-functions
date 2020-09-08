<#
.SYNOPSIS
Automation script for scaling elastic pool
.PARAMETER All
$ResourceGroupName = 'Also-Ecom-PROD'
$ServerName = 'also-ecom'
$DatabaseName = 'XLINK'
$LicenseType = 'LicenseIncluded'
$Edition = 'Hyperscale'
$RequestedService = 'HS_Gen5_14' # 'HS_Gen5_4'
$ReplicaCount = 1
#>

param(
    [parameter(Mandatory = $true)][string]$ResourceGroupName,
    [parameter(Mandatory = $true)][string]$ServerName,
    [parameter(Mandatory = $true)][string]$DatabaseName,
    [parameter(Mandatory = $true)][string]$LicenseType,
    [parameter(Mandatory = $true)][string]$RequestedService,
    [parameter(Mandatory = $true)][int]$ReplicaCount
)

# Connect to Azure using AzureRunAsConnection service principal
$connectionName = 'AzureRunAsConnection'
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    'Logging in to Azure...'
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint |`
        Out-Null
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Check if scaling is needed
[bool]$doScale = $false
$dbProp = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName | `
    Select-Object -Property DatabaseName, CurrentServiceObjectiveName

if ($dbProp.CurrentServiceObjectiveName -ne $RequestedService) {
    $doScale = $true
}

# Scale database
if ($doScale) {
    $scaleCmd = {
        Set-AzSqlDatabase -DatabaseName $DatabaseName `
            -RequestedServiceObjectiveName $RequestedService `
            -LicenseType $LicenseType `
            -ReadReplicaCount $ReplicaCount `
            -ServerName $ServerName `
            -ResourceGroupName $ResourceGroupName
    }
    "Scaling database to: $RequestedService"
    $scaleExec = Measure-Command { & $scaleCmd }
    $scaleExec.ToString('hh\:mm\:ss\.fff')
} else {
    'Scaling not required'
}
