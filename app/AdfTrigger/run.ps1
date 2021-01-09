<#
.SYNOPSIS
Function for turning on/off Azure Data Factory triggers.
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Exclude triggers from running
[string[]]$ExcludedTriggers = 'EveryTwoHoursTrigger'
if ($Request.Body.StartTriggers) {
    $getTriggerState = 'Started'
}
else {
    $getTriggerState = 'Stopped'
    $ExcludedTriggers += 'NightlyTrigger'  # don't stop trigger
}

# Get triggers that are not excluded and in state that needed to be changed
$triggersADF = Get-AzDataFactoryV2Trigger -DataFactoryName $Request.Body.DataFactoryName -ResourceGroupName $Request.Body.ResourceGroupName |`
    Where-Object { $_.Name -NotIn $ExcludedTriggers -and $_.RuntimeState -ne $getTriggerState }

foreach ($trigger in $triggersADF) {
    if ($Request.Body.StartTriggers) {
        Write-Host ('Starting trigger: ' + $trigger.Name)
        Start-AZDataFactoryV2Trigger -ResourceGroupName $Request.Body.ResourceGroupName -DataFactoryName $Request.Body.DataFactoryName -Name $trigger.Name -Force | Out-Null
    }
    else {
        Write-Host ('Stopping trigger: ' + $trigger.Name)
        Stop-AZDataFactoryV2Trigger -ResourceGroupName $Request.Body.ResourceGroupName -DataFactoryName $Request.Body.DataFactoryName -Name $trigger.Name -Force | Out-Null
    }
}

$response = [ordered]@{
    'DataFactoryName' = $Request.Body.DataFactoryName
    'TriggerStage' = $null
}

$response.TriggerStage = $triggersADF | ForEach-Object {
    Get-AzDataFactoryV2Trigger `
        -DataFactoryName $_.DataFactoryName `
        -ResourceGroupName $_.ResourceGroupName `
        -Name $_.Name | `
        Select-Object -Property @{Name = 'TriggerName'; Expression = { $_.Name } }, RuntimeState
}

Write-Host (ConvertTo-Json $response)
# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $response
    })
