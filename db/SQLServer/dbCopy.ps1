<#
.Synopsis
Skrypt tworzący dacpac ze wszystkich baz na serwerach SQL określonych w $sqlServers.
.Description
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.Example
db\SQLServer\dbCopy.ps1 -databaseName 'DOCS'
#>

param (
    [string]$databaseName = 'EDI'
)

# include common functions
. '.include\func_sql.ps1'
. '.include\func_azcommon.ps1'

<### Switch to source subscription ###>
Write-Output "`nSet source subsription"
(Connect-Subscription -Subscription '4933eec9-928e-4cca-8ce3-8f0ea0928d36').Name    # ALSO IL PROD

# Parameters
$srcServerName = 'also-ecom'
$dstServerName = 'also-ecom-dev'
$tmpDbName = $databaseName + '2'

# Get server and database properties
Write-Output 'Get server and database properties'
$srcSrv = Get-AzSqlServer -ServerName $srcServerName | Select-Object -Property ServerName, ResourceGroupName, FullyQualifiedDomainName
$dbProps = Get-AzSqlDatabase -ResourceGroupName $srcSrv.ResourceGroupName -ServerName $srcServerName -DatabaseName $databaseName | Select-Object -Property DatabaseName, ElasticPoolName, MaxSizeBytes, SkuName
if ($dbProps.SkuName -eq 'ElasticPool') {
    $srcElasticPool = Get-AzSqlElasticPool -ResourceGroupName $srcSrv.ResourceGroupName -ServerName $srcSrv.ServerName -ElasticPoolName $dbProps.ElasticPoolName | Select-Object -Property Edition, Family
}

<### Switch to destination subscription ###>
Write-Output "`nSet subsription"
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Select-Object -ExpandProperty Name; # ALSO IL DEV

$dstSrv = Get-AzSqlServer -ServerName $dstServerName | Select-Object -Property ServerName, ResourceGroupName, FullyQualifiedDomainName
$dstElasticPool = (Get-AzSqlElasticPool -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName).ElasticPoolName

if ($dbProps.SkuName -eq 'ElasticPool') {
    $storageMB = $dbProps.MaxSizeBytes / 1MB
    $tmpPool = New-AzSqlElasticPool -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName -ElasticPoolName $dbProps.ElasticPoolName -Edition $srcElasticPool.Edition -ComputeGeneration $srcElasticPool.Family -StorageMB $storageMB -vCore 4 -LicenseType 'BasePrice'
}

$cred = Get-Secret 'Az'
$qryCopyDb = "create database [$tmpDbName] as copy of [$($srcSrv.ServerName)].$databaseName;"
# Copy database
Invoke-SqlQuery -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred -Query $qryCopyDb

# Check import status and wait for the import to complete
$qryCheck = "select partner_database, percent_complete, replication_state_desc from sys.dm_database_copies where partner_database = '$databaseName';"
$qryState = "select state_desc from sys.databases where name = '$tmpDbName';"
$stateDesc = (Invoke-SqlQuery -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred -Query $qryState).state_desc
Invoke-SqlQuery -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred -Query $qryCheck

[Console]::WriteLine("`nCopying database")
$operationStart = Get-Date; $duration = '00:00:00.000'
while ($stateDesc -eq 'COPYING') {
    $operationStatus = Invoke-SqlQuery -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred -Query $qryCheck
    [Console]::WriteLine("$duration - $($operationStatus.replication_state_desc), percent complete: $($operationStatus.percent_complete)")
    Start-Sleep -s 10
    $duration = (New-TimeSpan -Start $operationStart).ToString('hh\:mm\:ss\.fff')
    $stateDesc = (Invoke-SqlQuery -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred -Query $qryState).state_desc
}
Write-Host "$duration - " -NoNewline; Write-Host 'Completed' -ForegroundColor Green

# Remove existing database
Write-Output "`nRemoving existing database if exists"
if (Get-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName -DatabaseName $databaseName -ErrorAction SilentlyContinue) {
    Remove-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName -DatabaseName $databaseName | Out-Null
}

# Change name of restored database
Write-Output 'Changing name of restored database'
Set-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName -DatabaseName $tmpDbName -NewName $databaseName | Out-Null

# Fix users in database
db\SQLServer\UsersFix.ps1 -Server $dstSrv.ServerName -Database $databaseName

# Move database to elastic pool
Write-Output "Moving database $databaseName to elastic pool $elasticPoolName"
Set-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstSrv.ServerName -DatabaseName $databaseName -ElasticPoolName $dstElasticPool | Out-Null

# Remove temporary elastic pool if exists
if ($dbProps.SkuName -eq 'ElasticPool') {
    $tmpPool | Remove-AzSqlElasticPool -Force | Out-Null
}

# The End
Write-Host "$databaseName database migration finished" -ForegroundColor Green
