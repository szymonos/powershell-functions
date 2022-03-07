<#
.SYNOPSIS
Windows Tweaks
#>

# *Check for installation date history.
Get-ChildItem -Path 'HKLM:\System\Setup\Source*' | `
    ForEach-Object { Get-ItemProperty -Path Registry::$_ } | `
    Select-Object ProductName, ReleaseID, CurrentBuild, @{Name = 'InstallDate'; e = { ([DateTime]'1970-01-01').AddSeconds($_.InstallDate) } } | `
    Sort-Object 'InstallDate'

# *Edit Windows Terminal settings.
# https://windowsterminalthemes.dev/
code -r "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# *Check windows default language / system version.
Get-Culture
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer, OsArchitecture
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\').BuildLabEx
[System.Environment]::OSVersion
Get-CimInstance -ClassName Win32_OperatingSystem
systeminfo.exe /fo csv | ConvertFrom-Csv | Select-Object OS*, System*, Hotfix* | Format-List

# *Turn of Sysmain (Superfetch) Service.
# via services
Get-Service -Name 'SysMain' | Select-Object Name, StartType, Status, DisplayName
Get-Service -Name 'SysMain' | ForEach-Object { Set-Service $_ -StartupType Disabled; Stop-Service $_ -Force }

# *Turn off Microsoft Telemetry.
# 1. Disable telemetry in registry
Get-Item 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
try {
    New-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -PropertyType DWord -Value 0 -ErrorAction Stop
} catch {
    Write-Output 'Property already exists'
}
# 2. Disable services
Get-Service -Name 'DiagTrack', 'dmwappushsvc', 'PcaSvc' -ErrorAction SilentlyContinue | Select-Object -Property Status, StartType, Name, DisplayName
Get-Service -Name 'DiagTrack', 'dmwappushsvc', 'PcaSvc' -ErrorAction SilentlyContinue | ForEach-Object { Set-Service -Name $_.Name -StartupType Disabled; Stop-Service -Name $_.Name -Force }

<#
.LINK Fix Excel - Unable to open https// <<PATH>> Cannot download the information you requested
https://docs.microsoft.com/en-us/office/troubleshoot/error-messages/cannot-locate-server-when-click-hyperlink
#>
try {
    Get-Item 'HKLM:\Software\Microsoft\Office\16.0\Common\Internet' -ErrorAction Stop
} catch {
    New-Item -Path 'HKLM:\Software\Microsoft\Office\16.0\Common' -Name 'Internet'
} finally {
    New-ItemProperty -Path 'HKLM:\Software\Microsoft\Office\16.0\Common\Internet' -Name ForceShellExecute -PropertyType DWord -Value 1 -ErrorAction SilentlyContinue
}

# *Windows 10 Clock in UTC.
try {
    Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -ErrorAction Stop
} catch {
    'RealTimeIsUniversal property not set.'
} finally {
    New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'RealTimeIsUniversal' -PropertyType DWord -Value 1 -ErrorAction SilentlyContinue
}

# *Fix Edge Chromium not working with Symantec Endpoint.
try {
    Get-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -ErrorAction Stop
} catch {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft' -Name 'Edge' | Out-Null
} finally {
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'RendererCodeIntegrityEnabled' -PropertyType DWord -Value 0 -ErrorAction SilentlyContinue
    # Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'RendererCodeIntegrityEnabled' -Value 0
}

# *Manage user autorun.
Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
# add program to autorun
$filePath = 'F:\usr\HRC\HRC.exe'; $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $fileName -PropertyType String -Value $filePath -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $fileName

# *Enable .NET Runtime Optimization Service High optimization.
Set-Location 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
.\ngen.exe executequeueditems

# *Show seconds in taskbar clock.
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -PropertyType DWord -Value 1 -Force
taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe

# *Turn off Fast Startup.
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0
taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe

# *Turn off hibernation.
powercfg -h off

<# *Turn on exploit protection to help mitigate against attacks | Microsoft Docs
https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/enable-exploit-protection?view=o365-worldwide
#>
Get-ProcessMitigation -Name vmcompute.exe
Set-ProcessMitigation -Name 'C:\Windows\System32\vmcompute.exe' -Disable CFG

# *Enable Long Paths
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled'
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force

# *Disable Bing search
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0 -PropertyType DWORD -Force

# *PowerShell as default SSH shell
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Program Files\PowerShell\7\pwsh.exe' -PropertyType String -Force

# *Regional settings.
Set-TimeZone -Id 'Central European Standard Time'

Get-Culture
Get-Culture -ListAvailable | Where-Object -Property 'Name' -Match '^en-'
Set-Culture en-GB
Get-ItemProperty -Path 'HKCU:\Control Panel\International'
Get-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sShortDate'
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sShortDate' -Value 'yyyy-MM-dd'
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sLongDate' -Value 'dddd, d MMMM yyyy'
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sTimeFormat' -Value 'HH:mm:ss'
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sShortTime' -Value 'HH:mm'
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'iFirstDayOfWeek' -Value '0'

# Disable watermark
Get-ItemPropertyValue -Path 'HKCU:\Control Panel\Desktop' -Name 'PaintDesktopVersion'
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'PaintDesktopVersion' -Value '0'

# *Fix cmd process exited with code 1 (0x00000001)
Remove-Item 'HKCU:\Software\Microsoft\Command Processor'

# *Fix Windows Update error 0x800f0988
Get-Service -Name wuauserv, cryptSvc, bits, msiserver | Stop-Service
Remove-Item -Force -Recurse C:\Windows\SoftwareDistribution\*
Remove-Item -Force -Recurse C:\Windows\System32\catroot2\*
Get-Service -Name wuauserv, cryptSvc, bits, msiserver | Start-Service
Dism.exe /Online /Cleanup-Image /StartComponentCleanup
Dism.exe /Online /Cleanup-Image /Restorehealth
sfc.exe /scannow

# *Modify Scheduled Tasks
Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\'
Disable-ScheduledTask -TaskName '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
Disable-ScheduledTask -TaskName '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
