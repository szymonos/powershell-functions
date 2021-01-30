<#
.SYNOPSIS
Function for testing smtp gateway.
.EXAMPLE POST method body
$Request = '{
    "Body": {
        "SmtpGtw": "SmtpGtw",
        "Recipient": "szymonos@contoso.com",
        "Subject": "Smtp test from function",
        "Message": "Test."
    }
}' | ConvertFrom-Json
#>
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'
# Write to the Azure Functions log stream.
Write-Host 'PowerShell HTTP trigger function processed a request.'

try {
    $response = Send-MailMessage `
        -SmtpServer $Request.Body.SmtpGtw `
        -Port 25 `
        -From "smtpgtw@$($Request.Body.Recipient.Split('@')[1])" `
        -To $Request.Body.Recipient `
        -Subject $Request.Body.Subject `
        -Body $Request.Body.Message
} catch {
    $response = $_.Exception.Message
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
