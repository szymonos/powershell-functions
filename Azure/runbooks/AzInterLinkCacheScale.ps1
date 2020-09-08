<#
.Example
Runbooks\AzInterLinkCacheScale.ps1
#>

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

## Convert UTC to CET
$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time')
$UTC = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$CET = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TZ)
# Get day of the week
$dayOfWeek = (Get-Date).DayOfWeek.value__
Write-Output ('Day of week: ' + $dayOfWeek + ' | Time: ' + $CET.ToString('yyyy-MM-dd HH:mm:ss'))

## Resource parameters
$resourceGroup = 'ALSO-Caches-PROD'
$cacheName = 'also-interlinkcache-prod'

$cacheProp = Get-AzRedisCache -ResourceGroupName $resourceGroup -Name $cacheName | Select-Object -Property Id, Size
$mem = (Get-AzMetric -ResourceId $cacheProp.Id -MetricName 'usedmemory' -StartTime (Get-Date).AddMinutes(-2)).Data | Select-Object -First 1 @{ Name = 'UsedGB'; Expression = { $_.Maximum / 1GB } }
[bool]$doScale = $true
# Check if it is a working day
if ($dayOfWeek -in 1..6 -and $CET.Hour -in 6,7) {
    $reqSvc = if ($dayOfWeek -ne 6) {
        Write-Output '53GB'
    } else {
        Write-Output '6GB'
    }

    if ([int]($cacheProp.Size).Replace('GB', '') -ge [int]$reqSvc.Replace('GB', '')) {
        $doScale = $false
    }
}
else {
    $reqSvc = if ($null -eq $mem.UsedGB) {
        $doScale = $false
    }
    elseif ($mem.UsedGB -lt 2.5) {
        Write-Output '2.5GB'
    }
    elseif ($mem.UsedGB -lt 6) {
        Write-Output '6GB'
    }
    elseif ($mem.UsedGB -lt 13) {
        Write-Output '13GB'
    }
    elseif ($mem.UsedGB -lt 26) {
        Write-Output '26GB'
    }
    else {
        $doScale = $false
    }

    if ($cacheProp.Size -eq $reqSvc) {
        $doScale = $false
    }
}

$size = [math]::round($mem.UsedGB, 1)

if ($doScale) {
    Write-Output ("Current memory usage`t: $($size)GB`nCurrent size`t`t: $($cacheProp.Size)`nScaling to`t`t: $reqSvc")
    Set-AzRedisCache -ResourceGroupName $resourceGroup -Name $cacheName -Size $reqSvc | Out-Null
}
else {
    Write-Output ("Current memory usage`t: $($size)GB`nCurrent size`t`t: $($cacheProp.Size)`nScaling not required.")
}
