<#
.SYNOPSIS
Function for testing connectivity from deployed function.
.EXAMPLE POST method body
$Request = '{
    "Query": {
        "name": "google.com",
        "port": 443
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
    $hostEntry = [Net.DNS]::GetHostEntry($Request.Query.name)
    $resolve = foreach ($address in $hostEntry.AddressList) {
        [PSCustomObject]@{HostName = $hostEntry.HostName; IPAddress = $address.IPAddressToString }
    }
} catch {
    $resolve = $_.Exception.Message
}

try {
$connection = New-Object System.Net.Sockets.TcpClient($Request.Query.name, $Request.Query.port)
$reachable = $connection.Connected
    $connection.Close()
} catch {
    $reachable = $_.Exception.Message
}

$response = [ordered]@{
    'ResolveDnsName' = $resolve
    'TestConnection'   = [PSCustomObject]@{Target = "$($resolve.IPAddress):$($Request.Query.port)"; Reachable = $reachable }
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
