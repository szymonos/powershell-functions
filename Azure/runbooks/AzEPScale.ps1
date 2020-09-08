<#
.SYNOPSIS
Automation script for scaling elastic pool
.PARAMETER All
$ResourceGroupName = 'Also-Ecom-PROD'
$ServerName = 'also-ecom'
$ElasticPoolName = 'ep-ecom-back'
$LicenseType = 'LicenseIncluded'
$Edition = 'BusinessCritical'
$Generation = 'Gen5'
$ReqCapacity = 6    # 4 downscale
#>

param(
    [parameter(Mandatory = $true)][string]$ResourceGroupName,
    [parameter(Mandatory = $true)][string]$ServerName,
    [parameter(Mandatory = $true)][string]$ElasticPoolName,
    [parameter(Mandatory = $true)][string]$LicenseType,
    [parameter(Mandatory = $true)][string]$Edition,
    [parameter(Mandatory = $true)][string]$Generation,
    [parameter(Mandatory = $true)][int]$ReqCapacity
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

## Check if scaling is needed
[bool]$doScale = $false
# Check elastic pool's computing power capacity
$epProp = Get-AzSqlElasticPool -ResourceGroupName $ResourceGroupName -ServerName $ServerName -ElasticPoolName $ElasticPoolName | `
    Select-Object -Property ResourceId, Capacity, StorageMB, MaxSizeBytes

if ($epProp.Capacity -ne $ReqCapacity) {
    $doScale = $true
}

# Check elastic pool's storage limit
$storagePct = (Get-AzMetric -ResourceId $epProp.ResourceId -MetricName 'allocated_data_storage_percent' -StartTime (Get-Date).AddMinutes(-2)).Data | `
    Select-Object -First 1 -ExpandProperty Maximum

if ($storagePct -gt 90) {
    $sizeMBytes = [Math]::Ceiling($epProp.MaxSizeBytes * $storagePct / 100 * 1.2 / 64GB) * 64KB
    $doScale = $true
} else {
    $sizeMBytes = $epProp.StorageMB
}

# Scale elastic pool
if ($doScale) {
    $scaleCmd = {
        Set-AzSqlElasticPool -ElasticPoolName $ElasticPoolName `
            -Edition $Edition `
            -ComputeGeneration $Generation `
            -StorageMB $sizeMBytes `
            -VCore $ReqCapacity `
            -ZoneRedundant `
            -LicenseType $LicenseType `
            -ServerName $ServerName `
            -ResourceGroupName $ResourceGroupName
    }
    "Scaling elastic pool to: $ReqCapacity cores / $($sizeMBytes / 1KB) GB"
    $scaleExec = Measure-Command { & $scaleCmd }
    $scaleExec.ToString('hh\:mm\:ss\.fff')
} else {
    'Scaling not required'
}
