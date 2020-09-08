<#
.DESCRIPTION
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.EXAMPLE
db\SQLServer\dbRestore.ps1
#>

$serverName = 'also-ecom'

#$excludeDbs = 'AC', 'Docs', 'CONTROL', 'DATASYNC', 'JOBS', 'LDH-ESD', 'master'
$srv = Get-AzSqlServer -ServerName $serverName | Select-Object -Property ServerName, ResourceGroupName
$dbs = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $serverName | `
    Where-Object -Property DatabaseName -NotIn $excludeDbs | `
    Sort-Object -Property MaxSizeBytes | `
    Select-Object -ExpandProperty DatabaseName

foreach ($db in $dbs) {
    #$db = $dbs[8]
    Write-Output "Migrating database $db"
    db\SQLServer\bacpac2local.ps1 -databaseName $db
    #db\SQLServer\dbCopy.ps1 -databaseName $db
}
