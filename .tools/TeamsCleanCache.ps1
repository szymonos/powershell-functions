<#
.Example
.tools\TeamsCleanCache.ps1
#>
$ErrorView = 'ConciseView'

Write-Host "Stopping Teams Process" -ForegroundColor Yellow
try {
    Get-Process -ProcessName Teams | Stop-Process -Force
    Start-Sleep -Seconds 3
    Write-Host "Teams Process Sucessfully Stopped" -ForegroundColor Green
}
catch {
    Write-Output 'Teams isnt''t running'
}
Write-Host "Clearing Teams Disk Cache" -ForegroundColor Yellow
try {
    #Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\application cache\cache" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\blob_storage" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\databases" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\cache" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\gpucache" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\Indexeddb" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\Local Storage" | Remove-Item -Recurse -Confirm:$false
    Get-ChildItem -Path $env:APPDATA\"Microsoft\Teams\tmp" | Remove-Item -Recurse -Confirm:$false
    Write-Host "Teams Disk Cache Cleaned" -ForegroundColor Green
}
catch {
    Write-Output $_
}

Write-Host "Cleanup Complete... Launching Teams" -ForegroundColor Green
Start-Process -FilePath $env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe
