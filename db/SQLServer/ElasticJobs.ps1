<#
.DESCRIPTION
https://docs.microsoft.com/en-us/azure/sql-database/elastic-jobs-powershell#create-the-elastic-job-agent
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.EXAMPLE
db\SQLServer\ElasticJobs.ps1
#>
# sign in to Azure account
Connect-AzAccount

# create the job database
Write-Output "Creating a blank SQL database to be used as the Job Database..."
$serverName = 'also-ldh-il-dev'
$elasticPoolName = 'ep-ecom-dev'
$jobDatabaseName = 'JOBS'
$srv = Get-AzSqlServer -ServerName $serverName | Select-Object -Property ServerName, ResourceGroupName, FullyQualifiedDomainName, SqlAdministratorLogin
if ([string]::IsNullOrEmpty($elasticPoolName)) {
    $jobDatabase = New-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DatabaseName $jobDatabaseName -RequestedServiceObjectiveName 'S0'
} else {
    $jobDatabase = New-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DatabaseName $jobDatabaseName -ElasticPoolName $elasticPoolName
}
#Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DatabaseName $jobDatabaseName
$jobDatabase

# Creating job agent
Write-Output "Creating job agent..."
$agentName = 'also-elasticagent-dev'
$jobAgent = $jobDatabase | New-AzSqlElasticJobAgent -Name $agentName
<#
$jobAgent = Get-AzSqlElasticJobAgent -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName
$jobAgent | Remove-AzSqlElasticJobAgent
#>
$jobAgent

# in the master database (target server)
# create the master user login, master user, and job user login
# Get credentials for sa
Write-Output 'Getting administrator credentials on the server'
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.Tags.login -in $srv.SqlAdministratorLogin, 'jobs_user' } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
$jobs_user_pass = ($creds | Where-Object -Property Login -eq 'jobs_user').Password

# create jobs_master login
$params = @{
    'database'        = 'master'
    'serverInstance'  = $srv.FullyQualifiedDomainName
    'username'        = $srv.SqlAdministratorLogin
    'password'        = ($creds | Where-Object -Property Login -eq $srv.SqlAdministratorLogin).Password
    'outputSqlErrors' = $true
    'query'           = "create login jobs_master with password = '$jobs_master_pass'"
}
Invoke-SqlCmd @params

# create jobs_master user in master database
$params.query = 'create user jobs_master from login jobs_master'
Invoke-SqlCmd @params

# create jobs_user login
$params.query = "create login jobs_user with password = '$jobs_user_pass'"
Invoke-SqlCmd @params

# for each target database
# create the jobuser from jobuser login and check permission for script execution
$targetDatabases = @( 'XLINK', 'RMA' )
$createJobUserScript = 'create user jobs_user from login jobs_user'
$grantDb_Owner = 'alter role db_owner add member [jobs_user]'

$targetDatabases | ForEach-Object {
    $params.database = $_
    $params.query = $createJobUserScript
    Invoke-SqlCmd @params
    $params.query = $grantDb_Owner
    Invoke-SqlCmd @params
}

# create job credential in Job database for master user
Write-Output "Creating job credentials..."
$loginPasswordSecure = (ConvertTo-SecureString -String $jobs_user_pass -AsPlainText -Force)

$masterCred = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'jobs_master', $loginPasswordSecure
$masterCred = $jobAgent | New-AzSqlElasticJobCredential -Name 'MASTERSTEVE' -Credential $masterCred

$jobCred = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList 'jobs_user', $loginPasswordSecure
$jobCred = $jobAgent | New-AzSqlElasticJobCredential -Name 'STEVE' -Credential $jobCred

Write-Output "Creating test target groups..."
<#
# create ServerGroup target group
$serverGroup = $jobAgent | New-AzSqlElasticJobTargetGroup -Name 'ServerGroup'
$serverGroup | Add-AzSqlElasticJobTarget -ServerName $srv.ServerName -RefreshCredentialName $masterCred.CredentialName # MASTERSTEVE
#>

# create DatabaseGroup including selected database
foreach ($db in $targetDatabases) {
    #$db = $targetDatabases[0]
    $databaseGroup = $jobAgent | New-AzSqlElasticJobTargetGroup -Name "$($db)Group"
    $databaseGroup | Add-AzSqlElasticJobTarget -ServerName $srv.ServerName -RefreshCredentialName $masterCred.CredentialName
    $databaseGroup | Add-AzSqlElasticJobTarget -ServerName $srv.ServerName -Database $db
}

<#
Remove-AzSqlElasticJobTargetGroup -ResourceGroupName $jobAgent.ResourceGroupName -ServerName $jobAgent.ServerName -AgentName $jobAgent.AgentName -Name 'XLINKGroup' -Force
#>
