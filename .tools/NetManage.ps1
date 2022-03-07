<#
.SYNOPSIS
Manage Network
.EXAMPLE
.tools\NetManage.ps1
#>

if ($test) {
    # *Resolve name
    $name = 'acrmusci.azurecr.io'
    # Windows
    Resolve-DnsName $name
    $ip = (Resolve-DnsName $name).IP4Address; $ip
    # Linux
    nslookup $name
    tracepath $name
    dig $name
    dig $name +short

    # Get preferred IP addres with ping method
    $ping = New-Object System.Net.NetworkInformation.Ping
    $ping.Send('google.com').Address.IPAddressToString

    # *Check connection
    $ip = '40.68.37.158'  # !old Azure SQL IP Address
    # Windows
    Test-Connection $ip -TcpPort 1433
    Test-NetConnection $ip -Port 1433  # Import-Module NetTCPIP
    # Linux
    telnet $ip 443
    curl -v "telnet://${ip}:443"
    sudo nping -c 1 --tcp -p 443 $ip

    # *Trace
    traceroute $name
    tracepatch $name
    tracert.exe $name

    # *Open ports
    nmap localhost

    # *check IPs of Azure SQL Servers
    $sqlServers = Import-Csv '.assets\config\Az\az_sqlservers.csv'
    foreach ($srv in $sqlServers.FullyQualifiedDomainName) {
        [PSCustomObject]@{ Name = $srv; IP4Address = (Resolve-DnsName $srv).IP4Address }
    }

    # *check Connection to Redis Cache Server
    (Resolve-DnsName 'sql-musci.database.windows.net').IP4Address | `
        ForEach-Object { [Console]::Write("$_ - "); Test-Connection $_ -TcpPort 6379 }

    # *check Connection to Redis Cache Server
    foreach ($ip in ('20.61.98.0', '20.61.98.1')) { Test-Connection $ip -TcpPort 443 }
    # *check connectivity to Azure SQL Servers
    @('52.236.184.163', '104.40.168.105') | ForEach-Object { [Console]::Write("$_ - "); Test-Connection $_ -TcpPort 1433 }
    @('52.236.184.163', '104.40.168.105') | ForEach-Object { Test-NetConnection $_ -Port 1433 }
}

if ($setup) {
    # Get network adapters
    Get-NetAdapter -Physical | Where-Object Status -EQ 'up'
    Get-NetAdapter | Where-Object Status -EQ 'up'

    # Get local IP adresses
    Get-NetIPAddress -AddressFamily IPv4 | Format-Table -AutoSize -Property PrefixOrigin, InterfaceIndex, InterfaceAlias, IPAddress, PrefixLength
    Get-NetIPConfiguration
    # Get public IP
    Invoke-RestMethod -Uri 'http://checkip.amazonaws.com/' | Tee-Object -Variable ip
    Invoke-RestMethod -Uri 'https://ifconfig.me/ip'
    curl 'https://ifconfig.me/ip'
    Invoke-RestMethod -Uri 'http://ifconfig.me/all.json'

    # Manage IPv4
    Get-NetAdapter
    $ethName = Get-NetAdapter -InterfaceIndex 13 | Select-Object -ExpandProperty Name
    $ipAddress = '10.10.10.55'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -AddressFamily IPv4 -PrefixLength 24

    $gtwAddress = '"10.10.10.10'
    New-NetIPAddress -InterfaceAlias $ethName -IPAddress $ipAddress -DefaultGateway $gtwAddress -AddressFamily IPv4 -PrefixLength 8
    Remove-NetIPAddress -InterfaceAlias $ethName

    # Measure dns server latency
    Test-Connection '9.9.9.9' -Count 10 | Tee-Object -Variable lat; $lat | Measure-Object Latency -AllStats

    # Update the DNS Server.
    Get-DnsClientServerAddress
    $dnsAddresses = @('8.8.8.8', '8.8.4.4')         # Google
    $dnsAddresses = @('1.1.1.1', '1.0.0.1')         # Cloudflare
    $dnsAddresses = @('9.9.9.9', '149.112.112.112') # Quad9
    Set-DnsClientServerAddress -InterfaceAlias $ethName -ServerAddresses $dnsAddresses

    Get-NetIPConfiguration -InterfaceAlias $ethName

    # Check If network card is set to public category Enable-PSRemoting will fail, so change it to private/domain
    Get-NetConnectionProfile
    Set-NetConnectionProfile -InterfaceAlias 'vEthernet (Internal)' -NetworkCategory Private
}
<# *Set up a Hyper-V NAT network
.LINK
https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network
#>
if ($nat) {
    New-VMSwitch -SwitchName 'NAT Network' -SwitchType Internal
    $ifIndex = (Get-NetAdapter -Name 'vEthernet (NAT Network)').InterfaceIndex
    New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $ifIndex
    New-NetNat -Name 'VMNAT' -InternalIPInterfaceAddressPrefix 192.168.0.0/24

    Get-NetNat
    Get-NetIPAddress -InterfaceIndex $ifIndex
}
