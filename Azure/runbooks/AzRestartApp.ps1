<#
.DESCRIPTION
Runbook for restarting specified web app.
.PARAMETER ResourceGroupName
Resource group name of the specified Web App
.PARAMETER WebAppName
Web App Name
#>

param(
    [parameter(Mandatory = $true)] [string]$ResourceGroupName,
    [parameter(Mandatory = $true)] [string]$WebAppName
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

$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time')
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $WebAppName |`
    Select-Object Name, Kind, State, @{Name = 'LastModified'; Expression = {[System.TimeZoneInfo]::ConvertTimeFromUtc($_.LastModifiedTimeUtc, $TZ)}}
