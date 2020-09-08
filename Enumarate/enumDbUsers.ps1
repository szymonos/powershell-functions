<#
.Synopsis
.Example
Enumarate\enumDbUsers.ps1
#>

$ErrorActionPreference = 'Stop'
# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

$dbExcludeProperties = 'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors'

# SQL queries used in script
$qryLogins = [System.IO.File]::ReadAllText('.\.include\sql\sel_logins.sql')
$qryUsers = [System.IO.File]::ReadAllText('.\.include\sql\sel_principals.sql')
function Add-LoginVerification {
    param (
        $Users
    )
    foreach ($user in $Users) {
        $loginFound = $logins | Where-Object { $_.name -eq $user.name -and $user.authentication_type -eq 1 }
        if ($null -eq $loginFound) {
            $user | Add-Member -MemberType NoteProperty -Name 'HasLogin' -Value $false
        }
        else {
            $user | Add-Member -MemberType NoteProperty -Name 'HasLogin' -Value $true
        }
    }
}

# Get list of servers form Azure storage table
Write-Output 'Getting list of SQL Servers'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$table = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext -ErrorAction SilentlyContinue
$sqlServers = Get-AzTableRows -Table $table
# Get context of table where database users will be stored to
$table = Select-AzTable -TableName 'AzDbUsers' -StorageContext $StorageContext

Write-Output 'Getting list of subscriptions'
$subscriptions = Get-AzSubscription | Where-Object -Property Id -ne '02c57fdb-6ccc-4892-950d-c008cbb24d5d' | Sort-Object -Property Name | Select-Object -Property Id, Name

$db_users = @()
foreach ($sub in $subscriptions) {
    Connect-Subscription -Subscription $sub.Id | Out-Null
    Write-Output ("`n" + 'Subscription ' + $sub.Name)
    $subServers = $sqlServers | Where-Object { $_.PartitionKey -eq $sub.Id }
    $keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName

    Write-Output 'Enumerating databases on server:'
    foreach ($srv in $subServers) {
        Write-Output (' - ' + $srv.ServerName)
        # Retreive administrator credentials
        $secretName = $srv.SqlAdministratorLogin
        $creds = Get-AzKeyVaultLoginPass -VaultName $keyVault -SecretName $secretName

        # Get list of logins on server
        $connStrMaster = Resolve-ConnString -ServerInstance $srv.FQDN -User $creds.UserName -Password $creds.Password
        $logins = Invoke-Sqlcmd -Query $qryLogins -ConnectionString $connStrMaster

        # Get list of SQL databases
        $dbList = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName |
            Where-Object { $_.DatabaseName -ne 'master' } |
            Select-Object -Property DatabaseName, Status

        foreach ($db in $dbList) {
            #$db = $dbList[0]
            $connStr = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $creds.UserName -Password $creds.Password
            Write-Output ('Processing database ' + $db.DatabaseName)
            if ($db.Status -eq 'Paused') {
                Start-AzSqlDatabase -ConnectionString $connStr
            }
            try {
                $instanceUsers = Invoke-Sqlcmd -Query $qryUsers -ConnectionString $connStr |
                    Where-Object { $_.type -eq 'S' -and $_.authentication_type -eq 1 } |
                    Select-Object -Property principal_id, name, authentication_type
                Add-LoginVerification -Users $instanceUsers
                $usersToDrop = $instanceUsers | Where-Object { !$_.HasLogin }
                #$usersToDrop | Format-Table -AutoSize
                foreach ($user in $usersToDrop.name) {
                    try {
                        $qryDropUser = "drop user [$user]"
                        Invoke-Sqlcmd -Query $qryDropUser -ConnectionString $connStr
                        Write-Output ($user + ' - user dropped')
                    }
                    catch {
                        $error[0].Exception
                    }
                }
                $users = Invoke-Sqlcmd -Query $qryUsers -ConnectionString $connStr |
                    Where-Object { $_.type -notin ('A', 'R') } |
                    Select-Object -ExcludeProperty $dbExcludeProperties
            }
            catch {
                Write-Warning ($db + ' - cannot get list of users in database')
            }
            $db_users += $users | Select-Object -Property * `
                , @{ Name = 'DatabaseName'; Expression = { $db.DatabaseName } } `
                , @{ Name = 'ServerName'; Expression = { $srv.ServerName } } `
                , @{ Name = 'SubscriptionId'; Expression = { $sub.Id } } `
                , @{ Name = 'Subscription'; Expression = { $sub.Name } }
        }
    }
}

# Enumerate object properties
$properties = ($db_users | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -ne 'SubscriptionId' }

# Clear target storage table
Remove-AzTableRows -Table $table
# Set properties for Add-AzTableRow function
foreach ($user in $db_users) {
    $partitionKey = $user.SubscriptionId
    $prop = @{ };
    foreach ($p in $properties) {
        $prop.Add($p, $user.($p))
    }
    Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey (New-Guid).Guid -Property $prop
}
