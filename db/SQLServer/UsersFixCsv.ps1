<#
.Synopsis
.Example
db\SQLServer\UsersFixCsv.ps1
db\SQLServer\UsersFixCsv.ps1 -Server 'also-ufo3x-dev'
db\SQLServer\UsersFixCsv.ps1 -Server 'also-ecom'
#>
param (
    [string]$Server
)
$ErrorActionPreference = 'Stop'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

Write-Output 'Getting list of SQL servers'
$sqlServers = Import-Csv -Path '.\.assets\config\Az\az_sqlservers.csv'

if ([string]::IsNullOrEmpty($Server)) {
    Write-Output 'Select server for processing'
    $sqlServers | Format-Table -AutoSize -Property @{Name = 'Id'; Expression = { $_.RowKey } }, ServerName, Subscription
    $srvId = Read-Host -Prompt 'Id'
    $srv = $sqlServers | Where-Object { $_.RowKey -eq $srvId }
} else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
}
if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

$subSelected = Connect-Subscription -Subscription $srv.SubscriptionId
Write-Output ('Switched to subscription: ' + $subSelected.Name)

# Get credentials for sa and user
Write-Output 'Getting administrator credentials on the server'
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.Tags.login -eq $srv.SqlAdministratorLogin } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password

if ($null -eq $creds) {
    Write-Warning ('User ' + $srv.SqlAdministratorLogin + ' not found in Key Vault' )
    break
}

# Get server databases
Write-Output 'Getting list of databases'
$dbs = Get-AzSqlDatabase -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | Where-Object { $_.DatabaseName -ne 'master'} | Select-Object -Property DatabaseName, Status

$dbCount = $dbs.Count
if ($dbCount -eq 0) {
    Write-Warning ('Haven''t found any database')
    break
} else {
    Write-Output ('Found ' + $dbCount + ' database(s)')
}

function Resolve-SQLQuery {
    param (
        [string]$User
    )
    return "alter user [$User] with login = [$User]
go"
}

$queryPath = '.include\sql\sel_principals.sql'
$query = [System.IO.File]::ReadAllText($queryPath)

foreach ($db in $dbs) {
    #$db = $dbs[0]
    $connStr = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $creds.Login -Password $creds.Password
    Write-Host ("`n" + 'Processing database ' + $db.DatabaseName) -ForegroundColor Green
    if ($db.Status -eq 'Paused') {
        Start-AzSqlDatabase -ConnectionString $connStr
    }
    try {
        $users = (Invoke-Sqlcmd -Query $query -ConnectionString $connStr -ErrorAction Stop | Where-Object { $_.type -eq 'S' -and $_.authentication_type -eq 1 }).name
        foreach ($user in $users) {
            #$user = $users[1]
            try {
                $qryFixUser = Resolve-SQLQuery -User $user
                Invoke-Sqlcmd -Query $qryFixUser -ConnectionString $connStr -ErrorAction Stop
                Write-Output ($user + ' - user fixed')
            }
            catch {
                Write-Warning $error[0].Exception.Message
            }
        }
    }
    catch {
        Write-Warning ($db + ' - cannot get list of users in database')
    }
}
