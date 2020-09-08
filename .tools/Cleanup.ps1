## Run as Administrator
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
powershell.exe -File '.\.include\Start-Cleanup.ps1'

# Analyze Component Store Size
Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
# Cleanup Component Store
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
