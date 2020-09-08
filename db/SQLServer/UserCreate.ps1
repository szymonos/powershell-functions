<#
.Synopsis
Creates login on server and user in database and optionally adding user to database role.
If login or user exists fixes credentials on server or database level.
Specyfying Database with wildcard '*' creates user in all databases on server.
.Example
db\SQLServer\UserCreate.ps1 -User 'ci_service'
db\SQLServer\UserCreate.ps1 -User 'ac_sso_svc' -Server 'also-ecom' -Database 'AC'
db\SQLServer\UserCreate.ps1 -User 'sqlread_ldh' -Server 'also-ldh-il-dev' -Database 'LDH' -Role 'db_datareader'
db\SQLServer\UserCreate.ps1 -User 'solp_dbo' -Server 'also-ecom' -Database 'SOLP' -Role 'db_owner'
db\SQLServer\UserCreate.ps1 -User 'ci_service' -Server 'also-ecom' -Database '*' -Role 'db_owner'
db\SQLServer\UserCreate.ps1 -User 'sqldev_read' -Server 'also-ldh-il-dev' -Database 'LDH' -Role 'db_datareader' -DbState -ShowPlan -ViewDef
db\SQLServer\UserCreate.ps1 -User 'sqldev_dpa' -Server 'also-ecom' -Database '*' -Role 'db_datawriter' -Exec -ViewDef -ShowPlan -AltEvent -Control -DbState
#>

param (
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $false)][string]$Server,
    [Parameter(Mandatory = $false)][string]$Database,
    [Parameter(Mandatory = $false)][string]$Role,
    [Parameter(Mandatory = $false)][switch]$Exec,
    [Parameter(Mandatory = $false)][switch]$ViewDef,
    [Parameter(Mandatory = $false)][switch]$ShowPlan,
    [Parameter(Mandatory = $false)][switch]$AltEvent,
    [Parameter(Mandatory = $false)][switch]$Control,
    [Parameter(Mandatory = $false)][switch]$DbState
)
$ErrorActionPreference = 'Stop'
$ErrorView = 'ConciseView'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

Write-Output 'Getting list of SQL Servers'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$srvTable = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext -ErrorAction SilentlyContinue
$sqlServers = Get-AzTableRows -Table $srvTable

if ([string]::IsNullOrEmpty($Server)) {
    Write-Output 'Select server for processing'
    $sqlServers | Format-Table -AutoSize -Property @{Name = 'Id'; Expression = { $_.RowKey } }, ServerName, Subscription
    $srvId = Read-Host -Prompt 'Id'
    $srv = $sqlServers | Where-Object { $_.RowKey -eq $srvId }
}
else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
}
if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

Connect-Subscription -Subscription $srv.PartitionKey | Out-Null

# Get credentials for sa and user
Write-Output 'Getting administrator credentials on the server'
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.Tags.login -in $srv.SqlAdministratorLogin, $User } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password

$credsa = $creds | Where-Object { $_.Login -eq $srv.SqlAdministratorLogin }
$credUser = $creds | Where-Object { $_.Login -eq $user }
if ($null -eq $credUser) {
    Write-Warning ('User ' + $user + ' not found in Key Vault' )
    break
}

# Get server databases
Write-Output 'Getting list of databases'
$srvDatabases = Get-AzSqlDatabase -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | Select-Object -Property DatabaseName, Status

# Select database
if ([string]::IsNullOrEmpty($Database)) {
    Write-Output 'Select database for processing'
    $i = 0
    $srvDatabases = $srvDatabases |
    Sort-Object -Property DatabaseName |
    ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i -PassThru
        $i++
    }
    $srvDatabases | Format-Table -AutoSize -Property Id, DatabaseName
    $dbId = Read-Host -Prompt 'Id'
    $dbs = $srvDatabases | Where-Object { $_.Id -eq $dbId }
}
elseif ($Database -eq '*') {
    $dbs = $srvDatabases
}
else {
    $dbs = $srvDatabases | Where-Object { $_.DatabaseName -eq $Database }
}

if (($dbs | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any database')
    break
}

# Create login
$connStrMaster = Resolve-ConnString -ServerInstance $srv.FQDN -User $credsa.Login -Password $credsa.Password
$queryMaster = "
if not exists (select * from sys.sql_logins where name = N'$($credUser.Login)')
	create login [$($credUser.Login)] with password = N'$($credUser.Password)'
else
	alter login [$($credUser.Login)] with password = N'$($credUser.Password)';"
try {
    Invoke-Sqlcmd -ConnectionString $connStrMaster -Query $queryMaster
    Write-Output ('Login [' + $credUser.Login + '] created on server ' + ($srv.ServerName).ToUpper())
}
catch {
    Write-Warning ('Login [' + $credUser.Login + '] couldn''t be created on server ' + ($srv.ServerName).ToUpper())
}

# Create user
$queryMaster = "if not exists (select * from sys.database_principals where name = '$($credUser.Login)')
	create user [$($credUser.Login)] for login [$($credUser.Login)]
else
	alter user [$($credUser.Login)] with login = [$($credUser.Login)];"
$queryDb = $queryMaster
if (![string]::IsNullOrEmpty($Role)) {
    $queryDb += "`nexec sp_addrolemember N'$Role', N'$($credUser.Login)';"
    Write-Output ('User will be added to role [' + $Role + ']')
}
if ($Exec) {
    $queryDb += "`ngrant execute to [$($credUser.Login)];"
    Write-Output ('User will have view definition permissions on database')
}
if ($ViewDef) {
    $queryDb += "`ngrant view definition to [$($credUser.Login)];"
    Write-Output ('User will have view definition permissions on database')
}
if ($ShowPlan) {
    $queryDb += "`ngrant showplan to [$($credUser.Login)];"
    Write-Output ('User will have view definition permissions on database')
}
if ($AltEvent) {
    $queryDb += "`ngrant alter any database event session to [$($credUser.Login)];"
    Write-Output ('User will have view definition permissions on database')
}
if ($Control) {
    $queryDb += "`ngrant control to [$($credUser.Login)];"
    Write-Output ('User will have view definition permissions on database')
}
if ($DbState) {
    $queryDb += "`ngrant view database state to [$($credUser.Login)];"
    Write-Output ('User will have view database state permissions on database')
}
foreach ($db in $dbs) {
    $connStr = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $credsa.Login -Password $credsa.Password
    if ($db.DatabaseName -eq 'master') {
    } else {
        $connStr = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $credsa.Login -Password $credsa.Password
    }
    if ($db.Status -eq 'Paused') {
        Start-AzSqlDatabase -ConnectionString $connStr
    }
    try {
        if ($db.DatabaseName -ne 'master') {
            Invoke-Sqlcmd -ConnectionString $connStr -Query $queryDb
        } else {
            Invoke-Sqlcmd -ConnectionString $connStr -Query $queryMaster
        }
        Write-Output ('User [' + $credUser.Login + '] created in database ' + $db.DatabaseName.ToUpper())
    }
    catch {
        Write-Warning ('User [' + $credUser.Login + '] couldn''t be created in database ' + $db.DatabaseName.ToUpper())
        $error[0].Exception.Message
    }
}
