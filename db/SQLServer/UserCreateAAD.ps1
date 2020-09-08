<#
.Synopsis
Creates login on server and user in database and optionally adding user to database role.
If login or user exists fixes credentials on server or database level.
Specyfying Database with wildcard '*' creates user in all databases on server.
.Example
db\SQLServer\UserCreateAAD.ps1 -User 'PL-SQLBizMags'
db\SQLServer\UserCreateAAD.ps1 -User 'PL-SQLAden' -Server 'also-ecom' -Database '*' -Exec
db\SQLServer\UserCreateAAD.ps1 -User 'PL-SQLAden' -Server 'also-ecom-dev' -Database '*' -Role 'db_owner'
db\SQLServer\UserCreateAAD.ps1 -User 'PL-SQLAden' -Server 'also-ldh-il-dev' -Database '*' -Role 'db_datareader' -Exec -ViewDef -ShowPlan -DbState
db\SQLServer\UserCreateAAD.ps1 -User 'PL-SQLDEVProductionSupport' -Server 'also-ecom' -Database '*' -Role 'db_datawriter' -Exec -ViewDef -ShowPlan -AltEvent -Control -DbState
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

Connect-Subscription -Subscription $srv.SubscriptionId | Select-Object -ExpandProperty Name

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
} elseif ($Database -eq '*') {
    $dbs = $srvDatabases
} else {
    $dbs = $srvDatabases | Where-Object { $_.DatabaseName -eq $Database }
}

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

# Build query
$queryMaster = "drop user if exists [$User];
create user [$User] from external provider;"
$queryDb = $queryMaster
if (![string]::IsNullOrEmpty($Role)) {
    $queryDb += "`nalter role [$Role] add member [$User];"
    Write-Output ('User will be added to role [' + $Role + ']')
}
if ($Exec) {
    $queryDb += "`ngrant execute to [$User];"
    Write-Output ('User will have view definition permissions on database')
}
if ($ViewDef) {
    $queryDb += "`ngrant view definition to [$User];"
    Write-Output ('User will have view definition permissions on database')
}
if ($ShowPlan) {
    $queryDb += "`ngrant showplan to [$User];"
    Write-Output ('User will have view definition permissions on database')
}
if ($AltEvent) {
    $queryDb += "`ngrant alter any database event session to [$User];"
    Write-Output ('User will have view definition permissions on database')
}
if ($Control) {
    $queryDb += "`ngrant control to [$User];"
    Write-Output ('User will have view definition permissions on database')
}
if ($DbState) {
    $queryDb += "`ngrant view database state to [$User];"
    Write-Output ('User will have view database state permissions on database')
}
foreach ($db in $dbs) {
    #$db = $dbs[0]
    if ($db.Status -eq 'Paused') {
        Start-AzSqlDatabase -ConnectionString $connStr
    }
    try {
        if ($db.DatabaseName -eq 'master') {
            #Write-Output $srv.FullyQualifiedDomainName $cred $db.DatabaseName $queryMaster
            Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Credential $cred -Query $queryMaster
        } else {
            #Write-Output $srv.FullyQualifiedDomainName $cred $db.DatabaseName $queryDb
            Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $queryDb
        }
        Write-Output ('User [' + $User + '] created in database ' + $db.DatabaseName)
    }
    catch {
        Write-Warning ('User [' + $User + '] couldn''t be created in database ' + $db.DatabaseName)
        $error[0].Exception.Message
    }
}
