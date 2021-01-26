<#
.SYNOPSIS
Function for testing connectivity from deployed function.
.EXAMPLE POST method body
$Request = '{
    "Body": {
        "Name": "google.com",
        "Port": 443
    }
}' | ConvertFrom-Json
#>
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

try {
    $hostEntry = [Net.DNS]::GetHostEntry($Request.Body.Name)
    $resolve = foreach ($address in $hostEntry.AddressList) {
        [PSCustomObject]@{
            HostName  = $hostEntry.HostName
            IPAddress = $address.IPAddressToString
        }
    }
} catch {
    $resolve = $_.Exception.Message
}

try {
    $connection = Test-Connection $Request.Body.Name -TcpPort $Request.Body.Port
} catch {
    $connection = $_.Exception.Message
}

$response = [ordered]@{
    'ResolveDnsName' = $resolve
    'TriggerState'   = [PSCustomObject]@{Target="$($Request.Body.Name):$($Request.Body.Port)"; Reachable=$connection}
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
