<#
.SYNOPSIS
Function for sending emails through specified smtp gateway.
.EXAMPLE POST method body
$Request = '{
    "Body": {
        "Recipient": "szymon.osiecki@also.com",
        "Message": "Test",
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
    $response = Send-MailMessage -SmtpServer SmtpGtw -Port 25 -From 'szymonos@contoso.com' -To $Request.Body.Recipient -Subject SmtpTest -Body $Request.Body.Message
}
catch {
    $response = $_.Exception.Message
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
