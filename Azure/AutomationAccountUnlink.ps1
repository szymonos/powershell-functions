# if you are not connected to Azure run the next command to login
$workspaceId = 'e81a8bfb-caaa-437a-998c-878056c2023a'

$automationSolutions = "Updates", "ChangeTracking", "AzureAutomation"
$automationAccount = 'devops-aa'

$workspace = (Get-AzOperationalInsightsWorkspace).Where( { $_.CustomerId -eq $workspaceId })

if (! $workspace ) {
    $subs = Get-AzSubscription

    if ($subs.Count -gt 1) {
        $subs
        Write-Error "You have access to multiple subscriptions. Run Select-AzSubscription to select the subscription with your workspace."
    }
    else {
        Write-Error "WorkspaceId not found: $workspaceId"
    }
    return
}

# If there is a linked automation account, remove the Automation and Control solutions
# unlink the automation account
try {
    $automationAccount = Get-AzResource -ResourceId ($workspace.ResourceId + "/linkedServices/automation") -ErrorAction Stop
}
catch {
    # continue
}

if ( $automationAccount ) {
    $enabledautomationSolutions = (Get-AzOperationalInsightsIntelligencePacks -ResourceGroupName $workspace.ResourceGroupName -WorkspaceName $workspace.Name).Where( { $_.Name -in $AutomationSolutions -and $_.Enabled -eq $true })
    foreach ($soln in $enabledAutomationSolutions.Name) {
        Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $workspace.ResourceGroupName -WorkspaceName $workspace.Name -IntelligencePackName $soln -Enabled $false
    }
    Remove-AzResource -ResourceId $automationAccount.ResourceId
}
