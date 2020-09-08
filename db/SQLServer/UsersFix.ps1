<#
.Synopsis
.Example
db\SQLServer\UsersFix.ps1
db\SQLServer\UsersFix.ps1 -Server 'also-ecom-dev' -Database 'XLINK2'
db\SQLServer\UsersFix.ps1 -Server 'also-ecom' -Database '*'
#>
param (
    [string]$Server,
    [string]$Database
)
$ErrorActionPreference = 'Stop'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

Write-Output 'Getting list of SQL Servers'
$sqlServers = Import-Csv '.\.assets\config\Az\az_sqlservers.csv'

if ([string]::IsNullOrEmpty($Server)) {
    Write-Output 'Select server for processing'
    $sqlServers | Format-Table -AutoSize -Property Id, ServerName, Subscription
    $srvId = Read-Host -Prompt 'Id'
    $srv = $sqlServers | Where-Object { $_.Id -eq $srvId }
} else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
}
if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

$subSelected = Connect-Subscription -Subscription $srv.SubscriptionId
Write-Output ('Switched to subscription: ' + $subSelected.Name)

# Get server databases
Write-Output 'Getting list of databases'
$srvDatabases = Get-AzSqlDatabase -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | `
    Where-Object -Property DatabaseName -ne 'master' | `
    Select-Object -Property DatabaseName, Status

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
} elseif ($Database -eq '*') {
    $dbs = $srvDatabases
} else {
    $dbs = $srvDatabases | Where-Object { $_.DatabaseName -eq $Database }
}

# Abort script if provided database haven't been found on the selected server
if (($dbs | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any database')
    break
}

# Get credentials
try {
    $cred = Get-Secret 'Az' -ErrorAction Stop
} catch {
    $cred = Get-Credential -Message 'Provide db_owner AAD credentials'
}

function Resolve-SQLQuery {
    param (
        [string]$User
    )
    return "alter user [$User] with login = [$User];"
}

$queryPath = '.include\sql\sel_principals.sql'
$queryUsers = [System.IO.File]::ReadAllText($queryPath)

foreach ($db in $dbs) {
    #$db = $dbs[0]
    Write-Host ("`n" + 'Processing database ' + $db.DatabaseName) -ForegroundColor Green
    if ($db.Status -eq 'Paused') {
        Start-AzSqlDatabase -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred
    }
    try {
        $users = (Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $queryUsers | `
                Where-Object { $_.type -eq 'S' -and $_.authentication_type -eq 1 }).name
        foreach ($user in $users) {
            #$user = $users[1]
            try {
                $qryFixUser = Resolve-SQLQuery -User $user
                Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $qryFixUser
                Write-Output ($user + ' - user fixed')
            }
            catch {
                Write-Warning $error[0].Exception.Message
                Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName `
                    -Database $db.DatabaseName `
                    -Credential $cred `
                    -Query "drop user [$user];"
                Write-Output ("User [$user] dropped")
            }
        }
    }
    catch {
        Write-Warning ($db.DatabaseName + ' - cannot get list of users in database')
    }
}
