<#
.Synopsis
.Example
Enumarate\enumAzSubscriptionsCsv.ps1
Enumarate\enumAzSubscriptionsCsv.ps1 -OutTerminal
#>

param (
    [switch]$OutTerminal
)
. '.\.include\func_azcommon.ps1'

# Enumerate Azure subscriptions
$subscriptions = Get-AzSubscription | Where-Object -Property Id -ne '02c57fdb-6ccc-4892-950d-c008cbb24d5d'| Sort-Object -Property Name | Select-Object Name, Id, TenantId, State
Write-Output ('Enumarating servers in subscription:')

if ($OutTerminal) {
    # Print results on terminal
    $subscriptions | Format-Table -AutoSize -Property Name, Id, State
}
else {
    $subscriptions | Export-Csv -Path '.\.assets\config\Az\az_subscriptions.csv' -NoTypeInformation -Encoding utf8
}
