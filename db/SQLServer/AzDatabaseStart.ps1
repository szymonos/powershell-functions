<#
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
db\SQLServer\AzDatabaseStart.ps1
#>
# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

# Get list of servers form Azure storage table
Write-Output 'Getting list of SQL Servers'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$table = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext -ErrorAction SilentlyContinue
$sqlServers = Get-AzTableRows -Table $table

[array]$excludedDbs = 'SCM_Copy', 'Lvision_ABC'
# Connect to Azure using AzureRunAsConnection service principal

Write-Output 'Getting list of subscriptions'
$subscriptions = Get-AzSubscription | Sort-Object -Property Name | Select-Object -Property Name, Id

foreach ($sub in $subscriptions) {
    Connect-Subscription -Subscription $sub.Id | Out-Null
    # Get all SQL Servers
    $sqlServers = Get-AzSqlServer | Select-Object -Property ServerName, FullyQualifiedDomainName, ResourceGroupName, SqlAdministratorLogin
    $keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName

    foreach ($srv in $sqlServers) {
        #$srv = $sqlServers[0]
        Write-Output (' - ' + $srv.ServerName)
        $creds = Get-AzKeyVaultSecret -VaultName $keyVault |
            Select-Object -Property Name, @{Name = 'Login'; Expression = { $_.Tags.login } } |
            Where-Object { $_.Login -eq $srv.SqlAdministratorLogin } |
            ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value ((Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText) -PassThru
            }

        # Get all paused SQL Databases
        $dbList = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |`
                Where-Object { $_.AutoPauseDelayInMinutes -gt 0 -and $_.DatabaseName -notin $excludedDbs } |`
                Select-Object -Property ServerName, DatabaseName, Status, @{Name = 'FQDN'; Expression = { $srv.FullyQualifiedDomainName } }

        # Try to wake up paused databases
        foreach ($db in $dbList) {
            #$db = $dbList[0]
            # Create connection string
            $ConnectionString = "Server=$($db.FQDN);Database=$($db.DatabaseName);User ID=$($creds.Login);Password=$($creds.Password);Encrypt=True"
            Write-Output ("`n" + $db.ServerName + '.' + $db.DatabaseName)
            $retry = $true
            $retryCount = 0
            while ($retry) {
                try {
                    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
                    $connection.Open()
                    ($retryCount -eq 0) ? 'Online' : 'Database resumed'
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
}
