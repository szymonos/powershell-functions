<#
.SYNOPSIS
Automation script updating Azure Cost billings
.PARAMETER PeriodsToGet
Number of latest month periods to get, starting from now.
#>

param(
    [int]$PeriodsToGet = 0
)

# Connect to Azure using AzureRunAsConnection service principal
$connectionName = 'AzureRunAsConnection'
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
    'Logging in to Azure...'
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint |`
        Out-Null
} catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Import-Module Orchestrator.AssetManagement.Cmdlets -ErrorAction SilentlyContinue
Import-Module SqlServer
Add-Type -AssemblyName System.Data
$ErrorActionPreference = 'Stop'

[datetime]$earliestPeriod = '2019-08-01'
$serverName = 'also-ecom.database.windows.net'
$database = 'CONTROL'
$sub = (Get-AzContext).Subscription

function New-DataTable {
    $dt = New-Object System.Data.DataTable
    # Create DataColumn objects of data types.
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'Name'; DataType = [System.Guid] }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'BillingPeriodName'; DataType = [System.String]; MaxLength = 8 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'ConsumedService'; DataType = [System.String]; MaxLength = 50 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'CostCenter'; DataType = [System.String]; MaxLength = 20 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'DepartmentName'; DataType = [System.String]; MaxLength = 20 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'InstanceLocation'; DataType = [System.String]; MaxLength = 20 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'InstanceName'; DataType = [System.String]; MaxLength = 127 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'UsageQuantity'; DataType = [System.Decimal] }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'PretaxCost'; DataType = [System.Decimal] }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'Currency'; DataType = [System.String]; MaxLength = 3 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'Product'; DataType = [System.String]; MaxLength = 255 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'SubscriptionName'; DataType = [System.String]; MaxLength = 20 }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'UsageStart'; DataType = [System.DateTime] }))
    $dt.Columns.Add((New-Object System.Data.DataColumn -Property @{ColumnName = 'InstanceId'; DataType = [System.String]; MaxLength = 255 }))
    return @(, ($dt))
}

$maxMonthsDiff = (12 * (Get-Date).Year + (Get-Date).Month) - (12 * ($earliestPeriod).Year + ($earliestPeriod).Month)

if ($maxMonthsDiff -lt $PeriodsToGet) {
    [datetime]$startPeriod = $earliestPeriod
    $PeriodsToGet = $maxMonthsDiff
} else {
    [datetime]$startPeriod = (Get-Date).AddMonths(-$PeriodsToGet).ToString('yyyy-MM') + '-01'
}

[array]$periodNames = @()
$i = 0
while ($i -le $PeriodsToGet) {
    [array]$periodNames += ($startPeriod.AddMonths($i)).ToString('yyyyMMdd')
    $i++
}

# Get credentials
$cred = Get-AutomationPSCredential -Name 'aa-sql-control'

# delete processed periods from the table
$query = "delete from dbo.AzBillings where UsageStart >= '$($periodNames[0])' and SubscriptionName = '$($sub.Name)';"
Invoke-Sqlcmd -ServerInstance $serverName -Database $database -Credential $cred -Query $query

# Bulk copy object instantiation
$connectionString = ("Server=tcp:$serverName,1433;Initial Catalog=$database;" + `
        "User ID=$($cred.UserName);Password='$($cred.GetNetworkCredential().Password)';")
$bulkCopy = New-Object('System.Data.SqlClient.SqlBulkCopy') $connectionString
# Define the destination table
$bulkCopy.DestinationTableName = 'dbo.AzBillings'

$exportProps = 'Name', 'BillingPeriodName', 'ConsumedService', 'CostCenter', 'DepartmentName', 'InstanceLocation', 'InstanceName', 'UsageQuantity', 'PretaxCost', 'Currency', 'Product', 'SubscriptionName', 'UsageStart', 'InstanceId'

foreach ($periodName in $periodNames) {
    "  $periodName"
    $usageDetail = Get-AzConsumptionUsageDetail -BillingPeriodName $periodName | Select-Object -Property $exportProps

    '  ...insert data to SQL table'
    # feed sql table
    $dt = New-DataTable
    foreach ($item in $usageDetail) {
        $dr = $dt.NewRow()
        foreach ($dc in $exportProps) {
            $dr[$dc] = $item.$dc
        }
        $dt.Rows.Add($dr)
    }
    # load the data into the target
    $bulkCopy.WriteToServer($dt)
}
