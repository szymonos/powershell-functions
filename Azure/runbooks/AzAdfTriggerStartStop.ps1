<#
.DESCRIPTION
Azure automation runbook used to start and stop ADF triggers to reduce subscription costs
.EXAMPLE
Runbooks\AzAdfTriggerStartStop.ps1 -ResourceGroupName 'Also-EcomDF-PROD' -DataFactoryName 'also-ecomdf-def' -StartTriggers -ExcludedTriggers 'EveryTwoHoursTriggerS', 'EveryTwoHoursTrigger_Orders'
#>
param(
    [parameter(Mandatory = $true)] [string]$ResourceGroupName,
    [parameter(Mandatory = $true)] [string]$DataFactoryName,
    [parameter(Mandatory = $true)] [switch]$StartTriggers
)

# Exclude triggers from running
[string[]]$ExcludedTriggers = 'EveryTwoHoursTriggerS', 'EveryTwoHoursTrigger_Orders'

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

# Get triggers that are not excluded and in state that needed to be changed
[string]$getTriggerState = if ($StartTriggers) { 'Started' } else { 'Stopped' }
$triggersADF = Get-AZDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName |`
    Where-Object { $_.Name -NotIn $ExcludedTriggers -and $_.RuntimeState -ne $getTriggerState }

# Show selected triggers
Write-Output ('Selected triggers:')
$triggersADF | Select-Object -Property DataFactoryName, @{Name = 'TriggerName'; Expression = { $_.Name } }, RuntimeState

foreach ($trigger in $triggersADF) {
    if ($StartTriggers) {
        Write-Output ('Starting trigger: ' + $trigger.Name)
        Start-AZDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $trigger.Name -Force | Out-Null
    }
    else {
        Write-Output ('Stopping trigger: ' + $trigger.Name)
        Stop-AZDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $trigger.Name -Force | Out-Null
    }
}

# Write triggers' state
Write-Output ('Triggers'' state:')
Get-AZDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName | `
    Select-Object -Property DataFactoryName, @{Name = 'TriggerName'; Expression = { $_.Name } }, RuntimeState
