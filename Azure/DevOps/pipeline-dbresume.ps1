# You can write your azure powershell scripts inline here.
# You can also pass predefined and custom variables to this script using arguments
Write-Output 'Resuming database $(DatabaseName)'
$ConnectionString = 'Server=$(ServerName);Database=$(DatabaseName);User ID=ci_service;Password=$(ciservice);Encrypt=True'
$retry = $true
$retryCount = 0
while ($retry) {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        Write-Output 'Database is online'
        $retry = $false
    }
    catch {
        $retryCount++
        Write-Output ('.' * $retryCount)
        if ($retryCount -ge 20) {
            Write-Warning 'Resuming database failed'
            break
        }
    }
    finally {
        $connection.Close()
    }
}
