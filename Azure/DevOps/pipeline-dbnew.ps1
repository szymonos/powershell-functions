<#
.SYNOPSIS
Creates new unique database dedicated to the build
.Description
Creates base named:
DbName-BuildNumber
Requires defined pipeline variables:
 -dbResourceGroup - SQL Server resource group
 -dbServer - name of Azure SQL Server
 -dbName - name of database
 -dbElasticPool - name od elastic pool
 -dbCollation - collation of database
#>

$dbServer = '$(dbServer)' -replace ('.database.windows.net', '')
$dbName = "$(dbName).$(Build.SourceBranchName).$(Build.BuildNumber)"

$newDb = New-AzSqlDatabase -ResourceGroupName $(dbResourceGroup) `
    -ServerName $dbServer `
    -DatabaseName $dbName `
    -ElasticPoolName $(dbElasticPool) `
    -CollationName $(dbCollation) `
    -MaxSizeBytes 1073741824

Write-Output $newDb
