<#
.SYNOPSIS
Windows Tweaks
#>

## Check for installation date history
Get-ChildItem -Path 'HKLM:\System\Setup\Source*' | `
    ForEach-Object { Get-ItemProperty -Path Registry::$_ } | `
    Select-Object ProductName, ReleaseID, CurrentBuild, @{Name = 'InstallDate'; e = { ([DateTime]'1970-01-01').AddSeconds($_.InstallDate) } } | `
    Sort-Object 'InstallDate'

# Check windows default language / system version
Get-Culture
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer, OsArchitecture
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\').BuildLabEx
[System.Environment]::OSVersion
Get-CimInstance -ClassName Win32_OperatingSystem
systeminfo.exe /fo csv | ConvertFrom-Csv | Select-Object OS*, System*, Hotfix* | Format-List

## Turn of Sysmain (Superfetch) Service
# Via services
Get-Service -Name 'SysMain' | Select-Object Name, StartType, Status, DisplayName
Get-Service -Name 'SysMain' | ForEach-Object { Set-Service $_ -StartupType Disabled; Stop-Service $_ -Force }

## Turn off Microsoft Telemetry
# 1. Disable telemetry in registry
Get-Item 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection'
try {
    New-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -PropertyType DWord -Value 0 -ErrorAction Stop
}
catch {
    Write-Output 'Property already exists'
}
# 2. Disable services
Get-Service -Name 'DiagTrack', 'dmwappushsvc', 'PcaSvc' -ErrorAction SilentlyContinue | Format-Table -AutoSize -Property Status, StartType, Name, DisplayName
Get-Service -Name 'DiagTrack', 'dmwappushsvc', 'PcaSvc' -ErrorAction SilentlyContinue | ForEach-Object { Set-Service -Name $_.Name -StartupType Disabled; Stop-Service -Name $_.Name -Force }

## Fix Excel - Unable to open https// <<PATH>> Cannot download the information you requested
<#
https://docs.microsoft.com/en-us/office/troubleshoot/error-messages/cannot-locate-server-when-click-hyperlink
#>
try {
    Get-Item 'HKLM:\Software\Microsoft\Office\16.0\Common\Internet' -ErrorAction Stop
} catch {
    New-Item -Path 'HKLM:\Software\Microsoft\Office\16.0\Common' -Name 'Internet'
} finally {
    New-ItemProperty -Path 'HKLM:\Software\Microsoft\Office\16.0\Common\Internet' -Name ForceShellExecute -PropertyType DWord -Value 1 -ErrorAction SilentlyContinue
}

## Manage user autorun
Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
# Add program to autorun
$filePath = 'F:\usr\HRC\HRC.exe'; $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $fileName -PropertyType String -Value $filePath -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $fileName

## Enable .NET Runtime Optimization Service High optimization
Set-Location 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
.\ngen.exe executequeueditems

## Show seconds in taskbar clock
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -PropertyType DWord -Value 1 -Force
taskkill.exe /F /IM explorer.exe; Start-Process explorer.exe

## Turn off hibernation
powercfg -h off
