## Run as Administrator
powershell.exe -c 'Set-ExecutionPolicy Unrestricted -Scope CurrentUser'
powershell.exe -File '.include/Start-Cleanup.ps1'

# Disk Ceanup
# https://winaero.com/cleanmgr-exe-command-line-arguments-in-windows-10/
cleanmgr.exe /h
cleanmgr.exe /SAGESET:1
cleanmgr.exe /SAGERUN:1
cleanmgr.exe /VERYLOWDISK
cleanmgr.exe /AUTOCLEAN
Get-Process -Name cleanmgr -ErrorAction SilentlyContinue #| Stop-Process
# Clean Microsoft Store cache
WSReset.exe

# Clean nuget cache
dotnet.exe nuget locals all --clear

# Analyze Component Store Size
Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
Dism.exe /Online /Cleanup-Image /CheckHealth
# Cleanup Component Store
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
