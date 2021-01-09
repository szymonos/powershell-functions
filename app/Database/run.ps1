<#
.SYNOPSIS
Function for scaling Azure SQL Databases.
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Check if scaling is needed
[bool]$doScale = $false
$dbProp = Get-AzSqlDatabase `
    -ResourceGroupName $Request.Body.ResourceGroupName `
    -ServerName $Request.Body.ServerName `
    -DatabaseName $Request.Body.DatabaseName | `
    Select-Object -Property DatabaseName, CurrentServiceObjectiveName

if ($dbProp.CurrentServiceObjectiveName -ne $Request.Body.RequestedService) {
    $doScale = $true
}

# Scale database
if ($doScale) {
    $response = Set-AzSqlDatabase -DatabaseName $Request.Body.DatabaseName `
        -RequestedServiceObjectiveName $Request.Body.RequestedService `
        -LicenseType $Request.Body.LicenseType `
        -ReadReplicaCount $Request.Body.ReplicaCount `
        -ServerName $Request.Body.ServerName `
        -ResourceGroupName $Request.Body.ResourceGroupName
    Write-Host (ConvertTo-Json $response)
    $statusCode = [HttpStatusCode]::OK
}
else {
    $response = $null
    Write-Host 'Scaling not required.'
    $statusCode = [HttpStatusCode]::NoContent
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Body       = $response
    })
