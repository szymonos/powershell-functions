<#
.SYNOPSIS
Removes database used in build
.Description
Requires defined pipeline variables:
 -dbResourceGroup - SQL Server resource group
 -dbServer - name of Azure SQL Server
 -dbName - name of database
#>
$dbServer = '$(dbServer)' -replace ('.database.windows.net', '')
$dbName = "$(dbName).$(Build.SourceBranchName).$(Build.BuildNumber)"
$removeDb = Remove-AzSqlDatabase -ResourceGroupName $(dbResourceGroup) `
    -ServerName $dbServer `
    -DatabaseName $dbName
Write-Output $removeDb
