<#
.Synopsis
.Example
db\SQLServer\UsersCheck.ps1
db\SQLServer\UsersCheck.ps1 -Server 'also-ecom'
#>
param (
    [string]$Server
)
$ErrorActionPreference = 'Stop'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

Write-Output 'Getting list of SQL servers'
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$srvTable = Get-AzStorageTable -Name 'AzSqlServers' -Context $StorageContext -ErrorAction SilentlyContinue
$sqlServers = Get-AzTableRows -Table $srvTable

<#
$srv = $sqlServers | Where-Object { $_.RowKey -eq 0 }
#>
if ([string]::IsNullOrEmpty($Server)) {
    Write-Output 'Select server for processing'
    $sqlServers | Format-Table -AutoSize -Property @{Name = 'Id'; Expression = { $_.RowKey } }, ServerName, Subscription
    $srvId = Read-Host -Prompt 'Id'
    $srv = $sqlServers | Where-Object { $_.RowKey -eq $srvId }
} else {
    $srv = $sqlServers | Where-Object { $_.ServerName -eq $Server }
} if (($srv | Measure-Object).Count -eq 0) {
    Write-Warning ('Haven''t found any server')
    break
}

Write-Output ('Changing subscription to: ' + $srv.Subscription)
Connect-Subscription -Subscription $srv.PartitionKey | Out-Null

Write-Output 'Getting subscribtion Key Vault name.'
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName

Write-Output 'Enumerating vault credentials.'
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.ContentType -eq 'sql-login' } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
$credsa = $creds | Where-Object { $_.Login -eq $srv.SqlAdministratorLogin }

# Get list of databases
Write-Output 'Getting list of databases'
$dbList = Get-AzSqlDatabase -ServerName $srv.ServerName -ResourceGroupName $srv.ResourceGroupName | Select-Object -Property DatabaseName, Status
$qryUsers = [System.IO.File]::ReadAllText('.\.include\sql\sel_principals.sql')

$userStatus = @()
foreach ($db in $dbList) {
    #$db = $dbList[1]
    $connsa = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $credsa.Login -Password $credsa.Password
    Write-Host ("`n" + 'Processing database ' + $db.DatabaseName) -ForegroundColor Green
    if ($db.Status -ne 'Online') {
        Start-AzSqlDatabase -ConnectionString $connsa
    }
    $userList = Invoke-Sqlcmd -Query $qryUsers -ConnectionString $connsa | Where-Object { $_.type -eq 'S' -and $_.authentication_type -eq 1 } | Select-Object -Property name
    foreach ($user in $userList) {
        #$user = $userList[1]
        $cred = $creds | Where-Object { $_.Login -eq $user.name }
        if (($cred | Measure-Object).Count -eq 0) {
            Write-Warning ($user.name + ' - missing credential in key vault')
            $verified = 'Missing'
        }
        else {
            $connStr = Resolve-ConnString -ServerInstance $srv.FQDN -Database $db.DatabaseName -User $cred.Login -Password $cred.Password
            try {
                $connection = New-Object System.Data.SqlClient.SqlConnection($connStr)
                $connection.Open()
                Write-Output ($user.name + ' - user credentials verified')
                $verified = 'Verified'
            } catch {
                Write-Warning $error[0].Exception.Message
                $verified = 'Failed'
            } finally {
                $connection.Close()
            }
        }
        $userStatus += $userList | Where-Object { $_.name -eq $user.name } | Add-Member -MemberType NoteProperty -Name 'Verified' -Value $verified -PassThru
    }
}

$i = 0
$userStatus |
Where-Object { $_.Verified -ne 'Verified' } |
ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name 'Id' -Value $i
    $i++
} | Format-Table -AutoSize -Property Id, ServerName, name, DatabaseName, Verified
