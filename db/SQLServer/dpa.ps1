<#
.Description
Script for generating temporary DPA sql users in databases
.Example
db\SQLServer\dpa.ps1 -DatabaseName 'XLINK'
#>
param (
    [Parameter(Mandatory = $true)][string]$DatabaseName = 'XLINK',
    [string]$ServerName = 'also-ecom'
)

. '.\.include\func_common.ps1'
. '.\.include\func_sql.ps1'
$env:USERNAME

$DatabaseName = ($DatabaseName).ToUpper()
$creds = [PSCustomObject]@{
    UserName     = 'dpa' + $DatabaseName.ToUpper() + '_' + (New-Password 5 ul) -replace ('\.', '') -replace ('-', '');
    Password = (New-Password 16 ulns)
    Created  = Get-Date
}

# Get credentials for sa and user
Write-Output 'Getting administrator credentials on the server'
$srv = Get-AzSqlServer -ServerName $ServerName | Select-Object -Property FullyQualifiedDomainName, SqlAdministratorLogin
$credsa = [PSCustomObject]@{
    Login = $srv.SqlAdministratorLogin
    Password = (Get-AzKeyVaultSecret -VaultName 'also-ecomvault-prod' -Name $srv.SqlAdministratorLogin).SecretValueText
}

# Create login
$connStrMaster = Resolve-ConnString -ServerInstance $srv.FullyQualifiedDomainName -User  $credsa.Login -Password $credsa.Password
$queryMaster = "if not exists (select 1 from sys.sql_logins where name = N'$($creds.UserName)')
	create login [$($creds.UserName)] with password = N'$($creds.Password)'
else
	alter login [$($creds.UserName)] with password = N'$($creds.Password)'
go"

try {
    Invoke-Sqlcmd -ConnectionString $connStrMaster -Query $queryMaster
    Write-Output ('Login ' + $($creds.UserName) + ' created on server ' + ($ServerName).ToUpper())
}
catch {
    Write-Warning ('Login ' + $($creds.UserName) + ' couldn''t be created on server ' + ($ServerName).ToUpper())
}

$connStr = Resolve-ConnString -ServerInstance $srv.FullyQualifiedDomainName -Database $Database -User $credsa.Login -Password $credsa.Password
# Create user
$queryDb = "if not exists (select 1 from sys.database_principals where name = N'$($creds.UserName)')
	create user [$($creds.UserName)] for login [$($creds.UserName)]
else
	alter user [$($creds.UserName)] with login = [$($creds.UserName)]
go
exec sp_addrolemember db_ddladmin, '$($creds.UserName)';
--exec sp_addrolemember db_securityadmin, '$($creds.UserName)';
exec sp_addrolemember db_datawriter, '$($creds.UserName)';
exec sp_addrolemember db_datareader, '$($creds.UserName)';
grant view definition to [$($creds.UserName)];
grant showplan to [$($creds.UserName)];
grant alter any database event session to [$($creds.UserName)];
grant control to [$($creds.UserName)];
grant view database state to [$($creds.UserName)];
grant execute to [$($creds.UserName)];
grant alter to [$($creds.UserName)];"

try {
    Invoke-Sqlcmd -ConnectionString $connStr -Query $queryDb
    Write-Output ('User ' + $creds.UserName + ' created in database ' + $DatabaseName)
}
catch {
    Write-Warning ('User ' + $creds.UserName + ' couldn''t be created in database ' + $DatabaseName)
}

$creds | Select-Object -Property Password, Created | Export-Csv -Path ".\.assets\config\$($creds.UserName).csv"
Write-Output $creds
