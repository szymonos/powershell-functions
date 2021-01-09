<#
.SYNOPSIS
Manage Network
.EXAMPLE
.tools\NetManage.ps1
#>

# Get network adapters
Get-NetAdapter -Physical | Where-Object Status -EQ 'up'
Get-NetAdapter | Where-Object Status -EQ 'up'

# Get local IP adresses
Get-NetIPAddress -AddressFamily IPv4 | Format-Table -AutoSize -Property PrefixOrigin, InterfaceIndex, InterfaceAlias, IPAddress, PrefixLength
Get-NetIPConfiguration -InterfaceIndex 11

if ($run) {
    # Get public IP
    $ip = Invoke-RestMethod -Uri 'https://ifconfig.me/ip'; $ip
    curl 'https://ifconfig.me/ip'
    $ip = Invoke-RestMethod -Uri 'http://ifconfig.me/forwarded'; $ip
    Invoke-RestMethod -Uri 'http://ifconfig.me/all.json'

    # Manage IPv4
    $ethName = Get-NetAdapter -InterfaceIndex 14 | Select-Object -ExpandProperty Name
    $ipAddress = '10.10.10.55'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -AddressFamily IPv4 -PrefixLength 24

    $gtwAddress = '"10.10.10.10'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -DefaultGateway $gtwAddress -AddressFamily IPv4 -PrefixLength 8
    Remove-NetIPAddress -InterfaceAlias $ethName

    #Update the DNS Server.
    $dnsAddresses = '8.8.8.8', '8.8.4.4'    # Google
    $dnsAddresses = '1.1.1.1', '1.0.0.1'    # Cloudflare
    Set-DnsClientServerAddress -InterfaceAlias $ethName -ServerAddresses $dnsAddresses
    Get-DnsClientServerAddress

    Get-NetIPConfiguration -InterfaceAlias $ethName

    # Check If network card is set to public category Enable-PSRemoting will fail, so change it to private/domain
    Get-NetConnectionProfile
    Set-NetConnectionProfile -InterfaceAlias 'vEthernet (Internal)' -NetworkCategory Private

    # Get preferred IP addres with ping method
    $ping = New-Object System.Net.NetworkInformation.Ping
    $ping.Send('google.com').Address.IPAddressToString

    # Resolve name and check connection
    Resolve-DnsName my-db.database.windows.net
}

# *check connectivity to Azure SQL Servers
foreach ($ip in ('52.236.184.163', '104.40.168.105')) {
    Test-Connection $ip -TcpPort 1433
}

<# *Set up a Hyper-V NAT network
.LINK
https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network
#>
New-VMSwitch -SwitchName "NAT Network" -SwitchType Internal
Get-NetAdapter  # 53
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex 53
New-NetNat -Name 'VMNAT' -InternalIPInterfaceAddressPrefix 192.168.0.0/24
Get-NetNat
Get-NetIPAddress -InterfaceIndex 53
