## Convert UTC to CET
$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time')
$UTC = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$CET = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TZ)
# Get day of the week
$dayOfWeek = (Get-Date).DayOfWeek.value__

# Check if it is working day between 09:00 and 17:00
if ($dayOfWeek -in 1..5 -and $CET.Hour -in 8..16) {
    $wakeUp = $true
}
else {
    $wakeUp = $false
}
Write-Output ('Day of week: ' + $dayOfWeek + ' | Time: ' + $CET.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Output ('WakeUp: ' + $wakeUp)

# Run if working hours
if ($wakeUp) {
    # Connect to Azure using AzureRunAsConnection service principal
    $connectionName = 'AzureRunAsConnection'
    try {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
        'Logging in to Azure...'
        Connect-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    }
    catch {
        if (!$servicePrincipalConnection) {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        }
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }

    # Get all SQL Servers
    $sqlServers = Get-AzSqlServer | Select-Object -Property ServerName, FullyQualifiedDomainName, ResourceGroupName

    # Get all paused SQL Databases
    $dbList = @()
    foreach ($srv in $sqlServers) {
        $dbList += Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | Where-Object { $_.Status -eq 'Paused' } | Select-Object -Property DatabaseName, @{Name = 'FQDN'; Expression = { $srv.FullyQualifiedDomainName } }
    }

    # Get the stored username and password from the Automation credential
    $SqlCredential = Get-AutomationPSCredential -Name 'calqa'
    if ($null -eq $SqlCredential) {
        throw "Could not retrieve credential asset. Check that you created this first in the Automation service."
    }

    $user = $SqlCredential.UserName
    $pass = $SqlCredential.GetNetworkCredential().Password

    # Try to wake up paused databases
    foreach ($db in $dbList) {
        # Create connection string
        $ConnectionString = "Server=$($db.FQDN);Database=$($db.DatabaseName);User ID=$user;Password=$pass;Encrypt=True"
        Write-Output ('Resuming database ' + $db.DatabaseName)
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
    }
}

<#
(Get-AzSqlServer).ServerName
$srv = Get-AzSqlServer | Where-Object { $_.ServerName -eq 'also-abcufo-dev' } | Select-Object -Property ServerName, FullyQualifiedDomainName, ResourceGroupName
Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName | Select-Object -Property ServerName, DatabaseName, Status, SkuName
#>
