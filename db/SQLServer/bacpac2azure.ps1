<#
.Synopsis
Skrypt tworzący dacpac ze wszystkich baz na serwerach SQL określonych w $sqlServers.
.Description
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.Example
db\SQLServer\bacpac.ps1 -databaseName 'DOCS'
#>

param (
    [string]$databaseName = 'LANG'
)

# Switch to PROD subscription
Write-Output "`nSet subsription"
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36' | Select-Object -ExpandProperty Name; # ALSO IL PROD

# Parameters
$serverName = 'also-ecom'
$storageAccount = 'alsoilprodsqlstorage'
$storageContainerName = 'bacpacs'
$storageResourceGroup = 'Also-Ecom-PROD'

# Get server and database properties
Write-Output 'Get server and database properties'
$srv = Get-AzSqlServer -ServerName $serverName | Select-Object -Property ServerName, ResourceGroupName, SqlAdministratorLogin
$resourceGroupName = $srv.ResourceGroupName
$dbProps = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName

# Set Storage Account context
Write-Output 'Set Storage Account context'
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageResourceGroup -Name $storageAccount).Value[1]
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
$storageUri = "https://$storageAccount.blob.core.windows.net/$storageContainerName/$databaseName.bacpac"
if (Get-AzStorageBlob -Container 'bacpacs' -Blob "$databaseName.bacpac" -Context $StorageContext -ErrorAction SilentlyContinue) {
    Remove-AzStorageBlob -Container 'bacpacs' -Blob "$databaseName.bacpac" -Context $StorageContext
}

# Get credentials for sa
Write-Output 'Getting administrator credentials on the server'
$cred = Get-Secret 'Az'
$user = $cred.GetNetworkCredential().UserName
$pass = $cred.GetNetworkCredential().Password
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.Tags.login -eq $srv.SqlAdministratorLogin } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
$pass = ConvertTo-SecureString $creds.Password -AsPlainText -Force
$cred.UserName
$cred.Password

# Export database to bacpac
$operationRequest = New-AzSqlDatabaseExport `
    -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -StorageKeyType 'StorageAccessKey' `
    -StorageKey $storageKey `
    -StorageUri $storageUri `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password `
    -AuthenticationType 'ADPassword' `
    -ErrorAction Stop

# Check export status and wait for the export to complete
$operationStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationRequest.OperationStatusLink
[Console]::WriteLine("`nExporting database $databaseName")
$operationStart = Get-Date; $duration = '00:00:00.000'
while ($operationStatus.Status -eq 'InProgress') {
    [Console]::WriteLine("$duration - $($operationStatus.StatusMessage)")
    Start-Sleep -s 10
    $operationStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationRequest.OperationStatusLink
    $duration = (New-TimeSpan -Start $operationStart).ToString('hh\:mm\:ss\.fff')
}
Write-Host "$duration - " -NoNewline; Write-Host $operationStatus.Status -ForegroundColor Green

# Switch to destination subscription
Write-Output "`nSet subsription"
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Select-Object -ExpandProperty Name; # ALSO IL DEV

$dstServerName = 'also-ecom-dev'
$dstDatabaseName = $databaseName + '2'
$dstSrv = Get-AzSqlServer -ServerName $dstServerName
$dstResourceGroupName = $dstSrv.ResourceGroupName
$elasticPoolName = 'ep-ecom-dev'

# Get credentials for sa
Write-Output 'Getting administrator credentials on the server'
$keyVault = (Get-AzKeyVault | Where-Object { $_.VaultName -like 'also-ecomvault-*' }).VaultName
$creds = Get-AzKeyVaultSecret -VaultName $keyVault |
Where-Object { $_.Tags.login -eq $dstSrv.SqlAdministratorLogin } |
ForEach-Object {
    $pass = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $_.Name).SecretValueText
    $_ | Add-Member -MemberType NoteProperty -Name 'Password' -Value $pass -PassThru
} | Select-Object -Property @{Name = 'Login'; Expression = { $_.Tags.login } }, Password
$pass = ConvertTo-SecureString $creds.Password -AsPlainText -Force

# Import bacpac to database with an S3 performance level
$operationRequest = New-AzSqlDatabaseImport `
    -ResourceGroupName $dstResourceGroupName `
    -ServerName $dstServerName `
    -DatabaseName $dstDatabaseName `
    -DatabaseMaxSizeBytes $dbProps.MaxSizeBytes `
    -StorageKeyType 'StorageAccessKey' `
    -StorageKey $storageKey `
    -StorageUri $storageUri `
    -Edition 'GeneralPurpose' `
    -ServiceObjectiveName 'GP_Gen5_4' `
    -AuthenticationType 'ADPassword' `
    -AdministratorLogin $cred.UserName `
    -AdministratorLoginPassword $cred.Password `
    -ErrorAction Stop

# Check import status and wait for the import to complete
$operationStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationRequest.OperationStatusLink
[Console]::WriteLine("`nImporting database")
$operationStart = Get-Date; $duration = '00:00:00.000'
while ($operationStatus.Status -eq 'InProgress') {
    [Console]::WriteLine("$duration - $($operationStatus.StatusMessage)")
    Start-Sleep -s 10
    $operationStatus = Get-AzSqlDatabaseImportExportStatus -OperationStatusLink $operationRequest.OperationStatusLink
    $duration = (New-TimeSpan -Start $operationStart).ToString('hh\:mm\:ss\.fff')
}
Write-Host "$duration - " -NoNewline; Write-Host $operationStatus.Status -ForegroundColor Green

# Remove bacpac used for database restore
Write-Output "`nRemoving $databaseName.bacpac from $storageAccount/$storageContainerName"
Remove-AzStorageBlob -Container 'bacpacs' -Blob "$databaseName.bacpac" -Context $StorageContext

# Fix users in database
db\SQLServer\UsersFix.ps1 -Server $dstServerName -Database $dstDatabaseName

# Remove existing database
Write-Output "`nRemoving existing database if exists"
if (Get-AzSqlDatabase -ResourceGroupName $dstResourceGroupName -ServerName $dstServerName -DatabaseName $databaseName -ErrorAction SilentlyContinue) {
    Remove-AzSqlDatabase -ResourceGroupName $dstResourceGroupName -ServerName $dstServerName -DatabaseName $databaseName
}

# Change name of restored database
Write-Output 'Changing name of restored database'
Set-AzSqlDatabase -ResourceGroupName $dstResourceGroupName -ServerName $dstServerName -DatabaseName $dstDatabaseName -NewName $databaseName | Out-Null

# Move database to elastic pool
Write-Output "Moving database $databaseName to elastic pool $elasticPoolName"
Set-AzSqlDatabase -ResourceGroupName $dstResourceGroupName -ServerName $dstServerName -DatabaseName $databaseName -ElasticPoolName $elasticPoolName | Out-Null

# The End
Write-Host "$databaseName database migration finished" -ForegroundColor Green
