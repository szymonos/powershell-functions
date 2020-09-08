<#
.Synopsis
Skrypt odtwarzający bazy danych przez eksport/import bacpaców
https://docs.microsoft.com/en-us/sql/tools/sqlpackage-download
Download file:
$url = 'https://go.microsoft.com/fwlink/?linkid=2113703'
$downloads = Get-ItemPropertyValue -Path 'Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name '{374DE290-123F-4565-9164-39C4925E467B}'
$output = Join-Path -Path $downloads -ChildPath 'DacFramework.msi'
(New-Object System.Net.WebClient).DownloadFile($url, $output)
.Description
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.Example
db\SQLServer\SqlPackage.ps1 -DatabaseName 'XLINK' -CreatePac -Operation 'dac'
db\SQLServer\SqlPackage.ps1 -DatabaseName 'LANG' -CreatePac
db\SQLServer\SqlPackage.ps1 -DatabaseName 'LANG' -CreatePac -Operation 'dac'
db\SQLServer\SqlPackage.ps1 -DatabaseName 'RMA' -RestoreLocal
db\SQLServer\SqlPackage.ps1 -DatabaseName 'RMA' -RestoreLocal -CleanPac
db\SQLServer\SqlPackage.ps1 -DatabaseName 'RMA' -CreatePac -RestoreLocal
db\SQLServer\SqlPackage.ps1 -DatabaseName 'RMA' -RestoreLocal -CleanPac -CreatePac
db\SQLServer\SqlPackage.ps1 -DatabaseName 'LOGS' -CreatePac -srcServerName 'also-ecom' -dstServerName 'also-ecom-dev'
db\SQLServer\SqlPackage.ps1 -DatabaseName 'LDH-ESD' -RestoreRemote -srcServerName 'also-ecom' -dstServerName 'also-ecom-dev'
#>

param (
    [cmdletbinding(DefaultParametersetName = 'default')]
    [ValidateSet('bac', 'dac')][string]$Operation = 'bac',
    [switch]$CreatePac,
    [switch]$CleanPac,
    [string]$srcServerName = 'also-ecom',
    [string]$dstServerName = 'SQL2019',
    [Parameter(Mandatory = $false)][string]$DatabaseName = 'LOGS',
    [switch]$RestoreLocal,
    [switch]$RestoreRemote,
    [switch]$RestoreBcp
)

# Include functions
. '.\.include\func_sql.ps1'
. '.include\func_forms.ps1'

# Parameters
if ($RestoreRemote) { $CreatePac = $true }
$targetLocation = ($Operation -eq 'dac') ? 'C:\Source\dacpac' : 'C:\Source\bacpac'
$sqlPackage = 'C:\Program Files\Microsoft SQL Server\150\DAC\bin\SqlPackage.exe'

if (!(Test-Path $sqlPackage)) {
    Write-Warning ('SqlPackage is not installed')
    break
}

$dstDir = Join-Path -Path $targetLocation -ChildPath $srcServerName
if (!(Test-Path -Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir | Out-Null
}
$pacFile = Join-Path -Path $dstDir -ChildPath "$databaseName.$($Operation)pac"

# Switch to source subscription
Write-Output "`e[38;5;51mSet source subscription`e[0m"
$srv = Import-Csv '.\.assets\config\Az\az_sqlservers.csv' | Where-Object -Property ServerName -eq $srcServerName
Set-AzContext -SubscriptionId $srv.SubscriptionId | Select-Object -ExpandProperty Name; # ALSO IL PROD

if ($CreatePac) {

    # Get credentials for sa
    $cred = Get-Secret 'Az'
    $connStr = Resolve-ConnString -ServerInstance $srv.FullyQualifiedDomainName -Database $DatabaseName -Credential $cred -ConnectReplica

    if ($Operation -eq 'bac') {
        # Export bacpac
        Write-Output ("`n`e[38;5;51mExporting bacpac:`e[0m`n$pacFile")
        &$sqlPackage /Action:Export /TargetFile:$pacFile /SourceConnectionString:$connStr /OverwriteFiles:True /p:CommandTimeout='0'
    }
    else {
        # Extract dacpac
        Write-Output ("`n`e[38;5;51mExtracting dacpac:`e[0m`n$pacFile")
        &$sqlPackage /Action:Extract /TargetFile:$pacFile /SourceConnectionString:$connStr /OverwriteFiles:True /p:CommandTimeout='0'
    }

    # Check if extraction succeded
    if (!(Test-Path $pacFile)) {
        Write-Output "`e[91mError: Operation failed`e[0m"
        break
    }
}

if ($RestoreLocal) {
    # Cleaning pac file from unsupported features
    if ($CleanPac) {
        & 'db\SqlPackageClean.ps1' -pacFile $pacFile
    }

    $DatabaseName = ('Az-' + $DatabaseName)
    # Remove existing database
    Write-Output "`n`e[38;5;51mRemove database if exists`e[0m"
    if (Get-DbaDatabase -SqlInstance $dstServerName -Database $DatabaseName) {
        Remove-DbaDatabase -SqlInstance $dstServerName -Database $DatabaseName -Confirm:$false | Out-Null
    }

    $connStr = Resolve-ConnString -ServerInstance $dstServerName -Database $DatabaseName -User 'sa' -Password 't!CvGFtuX1fJTn2B'

    Write-Output "`n`e[38;5;51mDeploy pac on server`e[0m"
    if ($Operation -eq 'bac') {
        &$sqlPackage /Action:Import /SourceFile:$pacFile /TargetConnectionString:$connStr
    }
    else {
        &$sqlPackage /Action:Publish /SourceFile:$pacFile /TargetConnectionString:$connStr
    }
    # The End
    Write-Output "`n`e[92m$databaseName database migration finished`e[0m"
}


if ($RestoreRemote) {
    # Switch to destination subscription

    $dbProps = Get-AzSqlDatabase -ResourceGroupName $srv.ResourceGroupName -ServerName $srv.ServerName -DatabaseName $DatabaseName

    Write-Output "`n`e[38;5;51mSet destination subscription`e[0m"
    Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Select-Object -ExpandProperty Name; # ALSO IL DEV

    $elasticPoolName = 'ep-ecom-dev'
    $dstSrv = Get-AzSqlServer -ServerName $dstServerName | Select-Object -Property ServerName, ResourceGroupName, SqlAdministratorLogin, FullyQualifiedDomainName

    # Remove existing database
    Write-Output "`n`e[38;5;51mRemove database if exists`e[0m"
    if (Get-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstServerName -DatabaseName $databaseName -ErrorAction SilentlyContinue) {
        Remove-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName -ServerName $dstServerName -DatabaseName $databaseName | Out-Null
    }

    # Create empty database
    Write-Output "`n`e[38;5;51mCreate empty database`e[0m"
    New-AzSqlDatabase -ResourceGroupName $dstSrv.ResourceGroupName `
        -ServerName $dstSrv.ServerName `
        -DatabaseName $databaseName `
        -ElasticPoolName $elasticPoolName `
        -MaxSizeBytes $dbProps.MaxSizeBytes `
        -CollationName $dbProps.CollationName | Out-Null

    $connStr = Resolve-ConnString -ServerInstance $dstSrv.FullyQualifiedDomainName -Database $DatabaseName -Credential $cred
    $connMaster = Resolve-ConnString -ServerInstance $dstSrv.FullyQualifiedDomainName -Credential $cred

    # Import bacpac to database
    if ($Operation -eq 'bac') {
        &$sqlPackage /Action:Import /SourceFile:$pacFile /TargetConnectionString:$connStr
    }
    else {
        &$sqlPackage /Action:Publish /SourceFile:$pacFile /TargetConnectionString:$connStr
    }

    # Change database to Read-Write
    $query = "alter database [$dstDatabaseName] set read_write with no_wait;"
    Invoke-Sqlcmd -Connectionstring $connMaster -Query $query

    # Fix users in database
    Write-Output "`n`e[38;5;51mFix users in database`e[0m"
    db\SQLServer\UsersFix.ps1 -Server $dstServerName -Database $databaseName

    # The End
    Write-Output "`n`e[92m$databaseName database migration finished`e[0m"
}

if ($RestoreBcp) {
    # Cleaning pac file from unsupported features
    if ($CleanPac) {
        & 'db\SqlPackageCleanToDac.ps1' -pacFile $pacFile
    }

    $dstDatabaseName = ('Az-' + $DatabaseName)
    # Remove existing database
    if ($env:USERDNSDOMAIN) {
        $connStr = "Persist Security Info=False;Integrated Security=SSPI;Initial Catalog=$dstDatabaseName;Server=$dstServerName"
        $connMaster = "Persist Security Info=False;Integrated Security=SSPI;Initial Catalog=master;Server=$dstServerName"
    }
    else {
        $cred = Import-CliXml -Path "$($env:USERPROFILE)\sa.xml"
        $user = $cred.GetNetworkCredential().UserName
        $pass = $cred.GetNetworkCredential().Password
        $connStr = Resolve-ConnString -ServerInstance $dstServerName -Database $dstDatabaseName -User $user -Password $pass
        $connMaster = Resolve-ConnString -ServerInstance $dstServerName -Database 'master' -User $user -Password $pass
    }
    Write-Output "`n`e[38;5;51mRemove database if exists`e[0m"
    if (Get-SqlDatabase -Connectionstring $connStr) {
        $query = "alter database [$dstDatabaseName] set single_user with rollback immediate; drop database [$dstDatabaseName];"
        Invoke-Sqlcmd -Connectionstring $connMaster -Query $query
        #Remove-DbaDatabase -SqlInstance $dstServerName -Database $DatabaseName -SqlCredential $cred -Confirm:$false | Out-Null
    }

    Write-Output "`n`e[38;5;51mDeploy dacpac on server`e[0m"
    $dacFile = $pacFile.Replace('bac', 'dac')
    &$sqlPackage /Action:Publish /SourceFile:$dacFile /TargetConnectionString:$connStr

    # Change database to Read-Write
    $query = "alter database [$dstDatabaseName] set read_write with no_wait;"
    Invoke-Sqlcmd -Connectionstring $connMaster -Query $query

    #Import data using BCP utility
    #bcp /v
    $dataDir = Join-Path $dstDir -ChildPath (Join-Path $DatabaseName -ChildPath 'Data')
    Test-Path $dataDir
    $tables = Get-ChildItem -Path $dataDir -Directory
    foreach ($table in $tables) {
        #$table = $tables[0]
        $tableData = Get-ChildItem -Path $table.FullName -Filter '*.bcp' -File
        foreach ($bcp in $tableData) {
            #$bcp = $tableData[0]
            if ($env:USERDNSDOMAIN) {
                bcp.exe $table.Name IN $bcp.FullName -S $dstServerName -d $dstDatabaseName -T -N | Out-Null
            }
            else {
                bcp.exe $table.Name IN $bcp.FullName -S $dstServerName -d $dstDatabaseName -U $user -P $pass -N | Out-Null
            }
        }
    }
    # The End
    Write-Output "`n`e[92m$databaseName database migration finished`e[0m"
}
