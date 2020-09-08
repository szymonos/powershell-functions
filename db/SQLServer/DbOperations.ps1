<#
Import-Csv -Path '.\.assets\config\az_sqlservers.csv' | Format-Table -AutoSize

Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
db\SQLServer\DbOperations.ps1
db\SQLServer\DbOperations.ps1 -Server 'also-ecom' -Database 'XLINK'
db\SQLServer\DbOperations.ps1 -Server 'also-ecom' -Database '*' -Script '.test\drop_user.sql'
db\SQLServer\DbOperations.ps1 -Script '.include\sql\sel_principals.sql'
#>

param (
    [Parameter(Mandatory = $false)][string]$Server,
    [Parameter(Mandatory = $false)][string]$Database,
    [Parameter(Mandatory = $false)][string]$Script = '.include\sql\sel_srvproperty.sql',
    [Parameter(Mandatory = $false)][string]$ApplicationIntent = 'ReadWrite'
)
$ErrorActionPreference = 'Stop'
$ErrorView = 'ConciseView'

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
}
else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
}
if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

Connect-Subscription -Subscription $srv.SubscriptionId | Select-Object -ExpandProperty Name

<#
# Create database
$elasticPoolName = (Get-AzSqlElasticPool -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName).ElasticPoolName

Write-Output "`n`e[38;5;51mCreate empty database`e[0m"
New-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName `
    -ServerName $srv.ServerName `
    -DatabaseName 'DATASYNC' `
    -ElasticPoolName $elasticPoolName `
    -MaxSizeBytes 1073741824 `
    -CollationName 'Polish_CI_AS' | Out-Null

# Get server databases
Write-Output 'Getting list of databases'
$srvDatabases = Get-AzSqlDatabase -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | Select-Object -Property DatabaseName, Status
#>

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
$query = [System.IO.File]::ReadAllText($Script)

Write-Output ("Executing query on server: $($srv.ServerName).`n database:")
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
