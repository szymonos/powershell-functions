<#
.SYNOPSIS
Manage Network
.EXAMPLE
.tools\NetManage.ps1
#>

# Get network adapters
Get-NetAdapter -Physical | Where-Object Status -eq 'up'
Get-NetAdapter | Where-Object Status -eq 'up'

# Get local IP adresses
Get-NetIPAddress -AddressFamily IPv4 | Format-Table -AutoSize -Property PrefixOrigin, InterfaceIndex, InterfaceAlias, IPAddress, PrefixLength

if ($run) {
    # Get public IP
    $ip = Invoke-RestMethod -Uri 'http://ifconfig.me/ip'; $ip

    # Manage IPv4
    $ethName = Get-NetAdapter -InterfaceIndex 13 | Select-Object -ExpandProperty Name
    $ipAddress = '10.10.10.55'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -AddressFamily IPv4 -PrefixLength 24

    $gtwAddress = '"10.10.10.10'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -DefaultGateway $gtwAddress -AddressFamily IPv4 -PrefixLength 8
    Remove-NetIPAddress -InterfaceAlias $ethName

    #Update the DNS Server.
    $dnsAddresses = '8.8.8.8', '8.8.4.4'    # Google
    $dnsAddresses = '1.1.1.1', '1.0.0.1'    # Cloudflare
    Set-DnsClientServerAddress -InterfaceAlias $ethName -ServerAddresses $dnsAddresses

    Get-NetIPConfiguration -InterfaceAlias $ethName

    # Check If network card is set to public category Enable-PSRemoting will fail, so change it to private/domain
    Get-NetConnectionProfile
    Set-NetConnectionProfile -InterfaceAlias 'vEthernet (Internal)' -NetworkCategory Private

    # Get preferred IP addres with ping method
    $ping = New-Object System.Net.NetworkInformation.Ping
    $ping.Send('google.com').Address.IPAddressToString

    # Resolve name and check connection
    Resolve-DnsName also-ecom.database.windows.net
    Test-Connection 40.68.37.158 -TcpPort 1433
    Test-NetConnection 40.68.37.158 -Port 1433 # Import-Module NetTCPIP
}
