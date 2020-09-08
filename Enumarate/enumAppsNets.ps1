$webApps = Get-AzWebApp | Select-Object -Property Name, ResourceGroup, DefaultHostName, Kind, OutboundIpAddresses, PossibleOutboundIpAddresses, State, RepositorySiteName, Enabled, ServerFarmId
$webApps | Select-Object -Property Name, Kind, ResourceGroup, @{Name = 'ServicePlane'; Expression = { Split-Path $_.ServerFarmId -Leaf } } | Export-Csv -Path '.\.assets\export\apps.csv' -NoTypeInformation -Encoding utf8

get-vnet

$subNets = Get-AzVirtualNetwork -Name 'IL-PROD-VNET' -ResourceGroupName 'Also-IL-PROD' | `
    Get-AzVirtualNetworkSubnetConfig | `
    Select-Object -Property Name, @{Name = 'AddressPrefix'; Expression = { $_.AddressPrefix } }, ProvisioningState, @{Name = 'AssociationLinks'; Expression = { $_.ServiceAssociationLinks.Link } }

$subNets.ServiceAssociationLinks.Link

$subNets | Export-Csv -Path '.\.assets\export\subnets.csv' -NoTypeInformation -Encoding utf8

Split-Path $webApps.ServerFarmId -Leaf
