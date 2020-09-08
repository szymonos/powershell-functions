<#
.SYNOPSIS
Forcing PowerShell to use TLS 1.3
.LINK
https://blog.pauby.com/post/force-powershell-to-use-tls-1-2/
.EXAMPLE
.tools\TlsSupport.ps1
.tools\TlsSupport.ps1 -ForceTls
#>

param (
    [switch]$ForceTls
)

# Get the BaseType of Net.SecurityProtocolType
[Net.SecurityProtocolType]

# Get the PowerShell supported TLS versions
[enum]::GetNames([Net.SecurityProtocolType])

# Force PowerShell to use TLS 1.3
if ($ForceTls) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
}
