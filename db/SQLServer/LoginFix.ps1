<#
.Synopsis
Import-Csv -Path '.\.assets\config\az_sqlservers.csv' | Format-Table -AutoSize
.Example
db\SQLServer\LoginFix.ps1 -ServerName 'also-ecom-qa' -Login 'ac_sso_qa'
#>

param (
    [string]$ServerName = 'also-ecom-qa',
    [string]$Login = 'ac_sso_qa'
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

# Get credentials
try {
    $cred = Get-Secret 'Az' -ErrorAction Stop
} catch {
    $cred = Get-Credential -Message 'Provide db_owner AAD credentials'
}


$query = "if not exists (select * from sys.sql_logins where name = '$Login')
    create login [$Login] with password = N'$PWD'
else
    alter login [$Login] with password=N'$PWD'"

try {
    Invoke-SqlQuery -ServerInstance $srv.FullyQualifiedDomainName -Credential $cred -Query $query
    Write-Output ($Login + ' - login fixed')
} catch {
    Write-Warning ($Login + ' - login fix failed')
}
