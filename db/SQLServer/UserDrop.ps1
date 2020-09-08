<#
Import-Csv -Path '.\.assets\config\az_sqlservers.csv' | Format-Table -AutoSize

Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
db\SQLServer\UserDrop.ps1 -User ''
db\SQLServer\UserDrop.ps1 -User 'sqladen_read' -Server 'also-ldh-il-dev' -Database '*'
#>

param (
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $false)][string]$Server,
    [Parameter(Mandatory = $false)][string]$Database
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

# Get credentials
$cred = Get-Secret 'Az'

# Build query
$query = "drop user if exists [$User];"

Write-Output ("Dropping user [$User] on server ""$($srv.ServerName)"".`n database:")
foreach ($db in $dbs) {
    if ($db.Status -eq 'Paused') {
        Start-AzSqlDatabase -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred
    }
    try {
        Write-Output (' - ' + $db.DatabaseName)
        Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database $db.DatabaseName -Credential $cred -Query $query
    }
    catch {
        Write-Warning ('Couldn''t execute query on database: ' + $db.DatabaseName)
        $error[0].Exception.Message
    }
}

$query = "if exists (select * from sys.sql_logins where name = N'$User')
drop login [$User];"
try {
    Write-Output ('Dropping login on server')
    Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Database 'master' -Credential $cred -Query $query
}
catch {
    Write-Warning ('Couldn''t execute query on database: ' + $db.DatabaseName)
    $error[0].Exception.Message
}
