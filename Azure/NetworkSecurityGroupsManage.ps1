<#
.Synopsis
Script for managing network security group rules
.LINK
https://docs.microsoft.com/en-us/azure/service-fabric/scripts/service-fabric-powershell-add-nsg-rule
https://docs.microsoft.com/en-us/powershell/module/az.network/add-aznetworksecurityruleconfig
https://docs.microsoft.com/en-us/powershell/module/az.network/set-aznetworksecurityruleconfig
.Example
Azure\NetworkSecurityGroupsManage.ps1
#>

. '.include\func_azcommon.ps1'

$rgName = 'DevOps-RG-QA'
$nsgName = 'qa-migration-nsg'
$ruleName = 'RDP'
#$rulename = "allowAppPort$port"

[array]$sourceAddressPrefix = '10.21.0.0/16'
$sourceAddressPrefix += Invoke-RestMethod -Uri 'http://ifconfig.me/ip'

Connect-Subscription -Subscription 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa' | Out-Null # ALSO IL QA
# List all network security groups in subscription
Get-AzNetworkSecurityGroup | Select-Object -Property Name, ResourceGroupName

# Update the NSG.
$nsg = Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname
$nsgRule = $nsg | Get-AzNetworkSecurityRuleConfig -Name $rulename

$nsrc = Set-AzNetworkSecurityRuleConfig -Name $rulename -NetworkSecurityGroup $nsg -Protocol $nsgRule.protocol -SourcePortRange $nsgRule.sourcePortRange `
    -DestinationPortRange $nsgRule.destinationPortRange -SourceAddressPrefix $sourceAddressPrefix -DestinationAddressPrefix $nsgRule.destinationAddressPrefix `
    -Access $nsgRule.access -Priority $nsgRule.priority -Direction $nsgRule.direction
$nsrc | Set-AzNetworkSecurityGroup

<### Add the inbound security rules ###
$rgName = 'rg-vm-us'
$nsgName = 'vm-openvpn-us-nsg'
[array]$sourceAddressPrefix = Invoke-RestMethod -Uri 'http://ifconfig.me/ip'
$nsgRules = [PSCustomObject]@(
    #[PSCustomObject]@{ Priority = 300; Protocol = 'TCP'; Name = 'SSH'; Port = 22; Source = $sourceAddressPrefix }
    #[PSCustomObject]@{ Priority = 310; Protocol = 'TCP'; Name = 'RDP'; Port = 3389; Source = $sourceAddressPrefix }
    #[PSCustomObject]@{ Priority = 320; Protocol = 'TCP'; Name = 'HTTP'; Port = 80; Source = '*'; }
    [PSCustomObject]@{ Priority = 330; Protocol = 'TCP'; Name = 'HTTPS'; Port = 443; Source = '*'; }
    [PSCustomObject]@{ Priority = 340; Protocol = 'TCP'; Name = 'VPN-TCP'; Port = 943; Source = '*'; }
    [PSCustomObject]@{ Priority = 350; Protocol = 'UDP'; Name = 'VPN-UDP'; Port = 1194; Source = '*'; }
)
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName
foreach($rule in $nsgRules) {
    #$rule = $nsgRules[0]
    $nsg | Add-AzNetworkSecurityRuleConfig -Name $rule.Name -Access Allow `
    -Protocol $rule.Protocol -Direction Inbound -Priority $rule.Priority -SourceAddressPrefix $rule.Source -SourcePortRange '*' `
    -DestinationAddressPrefix '*' -DestinationPortRange $rule.Port
}
$nsg | Set-AzNetworkSecurityGroup
#>
