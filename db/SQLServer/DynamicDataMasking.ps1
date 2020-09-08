<#
# Set subscription
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
(Get-AzContext).Subscription.Name
db\SQLServer\DynamiDataMasking.ps1
#>

$resourceGroupName = 'Also-Ecom-PROD'
$serverName = 'also-ecom'
<#
$resourceGroupName = 'Also-IL-DEV'
$serverName = 'also-ufo3x-dev'
#>
$databaseName = 'XLINK'
$schemaName = 'dbo'
$tableName = 'BLAccounts'
$columnName = 'old_pass'
$maskingFunction = 'Text'
$prefixSize = 0
$suffixSize = 0
$replacementString = 'xxxxx'

New-AzSqlDatabaseDataMaskingRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SchemaName $schemaName `
    -TableName $tableName `
    -ColumnName $columnName `
    -MaskingFunction $maskingFunction `
    -PrefixSize $prefixSize `
    -SuffixSize $suffixSize `
    -ReplacementString $replacementString
