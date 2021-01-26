<#
.SYNOPSIS
Function for scaling Azure Redis Cache.
.EXAMPLE POST method body
$Request = '{
    "Body": {
        "ResourceGroupName": "RG-RedisCache",
        "CacheName": "redis-cache-prod",
        "ScaleDown": false,
        "DestSize": "26GB"
    }
}' | ConvertFrom-Json
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$cacheProp = Get-AzRedisCache -ResourceGroupName $Request.Body.ResourceGroupName -Name $Request.Body.CacheName | Select-Object -Property Id, Size
$mem = (Get-AzMetric -ResourceId $cacheProp.Id -MetricName 'usedmemory' -StartTime (Get-Date).AddMinutes(-2)).Data | Select-Object -Last 1 @{ Name = 'UsedGB'; Expression = { $_.Maximum / 1GB } }
[bool]$doScale = $true
# Check if it is a working day
if ($Request.Body.ScaleDown) {
    $Request.Body.DestSize = if ($null -eq $mem.UsedGB) {
        $doScale = $false
    } elseif ($mem.UsedGB -lt 2.5) {
        '2.5GB'
    } elseif ($mem.UsedGB -lt 6) {
        '6GB'
    } elseif ($mem.UsedGB -lt 13) {
        '13GB'
    } elseif ($mem.UsedGB -lt 26) {
        '26GB'
    } else {
        $doScale = $false
    }

    if ($cacheProp.Size -eq $Request.Body.DestSize) {
        $doScale = $false
    }
}

if ($doScale) {
    $response = Set-AzRedisCache -ResourceGroupName $Request.Body.ResourceGroupName -Name $Request.Body.CacheName -Size $Request.Body.DestSize
    Write-Host (ConvertTo-Json $response)
    $statusCode = [HttpStatusCode]::OK
} else {
    $response = $null
    Write-Host "Scaling not required."
    $statusCode = [HttpStatusCode]::NoContent
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Body       = $response
    })
