[array]$excludedDbs = 'SCM_Copy', 'Lvision_ABC'
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
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint |`
            Out-Null
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
    $dbList += Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |`
            Where-Object { $_.AutoPauseDelayInMinutes -gt 0 -and $_.DatabaseName -notin $excludedDbs } |`
            Select-Object -Property ServerName, DatabaseName, Status, @{Name = 'FQDN'; Expression = { $srv.FullyQualifiedDomainName } }
}

# Get the stored username and password from the Automation credential
$SqlCredential = Get-AutomationPSCredential -Name 'calqa'
if ($null -eq $SqlCredential) {
    throw 'Could not retrieve credential asset. Check that you created this first in the Automation service.'
}

$user = $SqlCredential.UserName
$pass = $SqlCredential.GetNetworkCredential().Password

# Try to wake up paused databases
foreach ($db in $dbList) {
    # Create connection string
    $ConnectionString = "Server=$($db.FQDN);Database=$($db.DatabaseName);User ID=$user;Password=$pass;Encrypt=True"
    Write-Output ("`n" + $db.ServerName + '.' + $db.DatabaseName)
    $retry = $true
    $retryCount = 0
    while ($retry) {
        try {
            $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $connection.Open()
            if ($retryCount -eq 0) {
                Write-Output 'Online'
            }
            else {
                Write-Output 'Database resumed'
            }
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
