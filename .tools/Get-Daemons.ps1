<#
.DESCRIPTION
Get TCP&UDP Network Daemons and Associated Processes
Make a lookup table by process ID
.EXAMPLE
.tools\Get-Daemons.ps1
Stop-Process -Id 21816
#>

$Processes = @{}
Get-Process -IncludeUserName | ForEach-Object {
    $Processes[$_.Id] = $_
}

# Query Listening TCP Daemons
Write-Host "`nTCP Daemons" -ForegroundColor 'Green' -NoNewline
Get-NetTCPConnection | `
    Where-Object { $_.LocalAddress -eq '0.0.0.0' -and $_.State -eq 'Listen' } | `
    Select-Object LocalPort `
    , @{Name = 'PID'; Expression = { $_.OwningProcess } } `
    , @{Name = 'UserName'; Expression = { $Processes[[int]$_.OwningProcess].UserName } } `
    , @{Name = 'ProcessName'; Expression = { $Processes[[int]$_.OwningProcess].ProcessName } } `
    , @{Name = 'Path'; Expression = { $Processes[[int]$_.OwningProcess].Path } } -Unique | `
    Sort-Object -Property LocalPort, ProcessName | Format-Table -AutoSize

# Query Listening UDP Daemons
Write-Host "UDP Daemons" -ForegroundColor 'Green' -NoNewline
Get-NetUDPEndpoint | `
    Where-Object { $_.LocalAddress -eq '0.0.0.0' } | `
    Select-Object LocalPort `
    , @{Name = 'PID'; Expression = { $_.OwningProcess } } `
    , @{Name = 'UserName'; Expression = { $Processes[[int]$_.OwningProcess].UserName } } `
    , @{Name = 'ProcessName'; Expression = { $Processes[[int]$_.OwningProcess].ProcessName } } `
    , @{Name = 'Path'; Expression = { $Processes[[int]$_.OwningProcess].Path } } -Unique | `
    Sort-Object -Property LocalPort, ProcessName | Format-Table -AutoSize
