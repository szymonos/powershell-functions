<#
.Synopsis
.Example
Enumarate\enumAzSqlServersCsv.ps1
Enumarate\enumAzSqlServersCsv.ps1 -OutTerminal
#>

param (
    [switch]$OutTerminal = $false
)
. '.\.include\func_azcommon.ps1'

# Enumerate Azure subscriptions
$subscriptions = Import-Csv -Path '.\.assets\config\Az\az_subscriptions.csv' | Select-Object -Property Id, Name

Write-Output ('Enumarating servers in subscription:')

# Enumerate SQL servers in all subscriptions
$sqlServers = @(); $i = 0
foreach ($sub in $subscriptions) {
    Write-Output (' - ' + $sub.Name)
    Connect-Subscription -Subscription $sub.Id | Out-Null
    $sqlServers += Get-AzSqlServer |
    Select-Object -Property `
        ServerName, ResourceGroupName, Location, ServerVersion, SqlAdministratorLogin, FullyQualifiedDomainName `
        , @{ Name = 'SubscriptionId'; Expression = { $sub.Id } } `
        , @{ Name = 'Subscription'; Expression = { $sub.Name } } |
    ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru
        $i++
    }
}

if ($OutTerminal) {
    # Print results on terminal
    $sqlServers | Format-Table -AutoSize -Property Id, ServerName, FQDN, ResourceGroupName, Subscription, Location, SqlAdministratorLogin
}
else {
    # Define the storage account and context for Azure storage table
    $sqlServers | Export-Csv -Path '.\.assets\config\Az\az_sqlservers.csv' -NoTypeInformation -Encoding utf8
}
