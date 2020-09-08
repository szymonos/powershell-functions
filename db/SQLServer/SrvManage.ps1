<#
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
db\SQLServer\SrvManage.ps1 -SetFW
#>

param (
    [switch]$SetFW,
    [switch]$SetAdm
)

. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

Write-Output 'Getting list of SQL Servers'
$sqlServersList = Import-Csv '.\.assets\config\Az\az_sqlservers.csv'
$subscriptions = Import-Csv '.\.assets\config\Az\az_subscriptions.csv'

$myIp = Invoke-RestMethod -Uri 'http://ifconfig.me/ip' # 93.174.24.11
<# Firewall Rules #>
$fwRules = @(
    [PSCustomObject]@{Name = 'SzymonDom'; Value = $myIp }
    #[PSCustomObject]@{Name = 'Roseville Office'; Value = '193.109.127.15'}
)

if ($SetFW) {
    foreach ($sub in $subscriptions) {
        $sqlServers = $sqlServersList | Where-Object { $_.SubscriptionId -eq $sub.Id }
        Connect-Subscription -Subscription $sub.Id | Out-Null
        foreach ($srv in $sqlServers) {
            foreach ($rule in $fwRules) {
                try {
                    Set-AzSqlServerFirewallRule -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -FirewallRuleName $rule.Name -StartIpAddress $rule.Value -EndIpAddress $rule.Value
                }
                catch {
                    New-AzSqlServerFirewallRule -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.serverName -FirewallRuleName $rule.Name -StartIpAddress $rule.Value -EndIpAddress $rule.Value
                }
            }
        }
    }
}

if ($setAdm) {
    foreach ($srv in $sqlServers) {
        if (((Get-AzContext).Subscription).Name -ne $srv.Subscription) {
            Set-AzContext -Subscription $srv.Subscription | Out-Null
        }
        Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DisplayName 'Szymon.Osiecki@also.com'
        #Get-AzSqlServerActiveDirectoryAdministrator -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | Select-Object -Property ServerName, DisplayName, ResourceGroupName
    }
}
