<#
.SYNOPSIS
Script collects consumption details in all subscriptions and writes them to table in database
.LINK
https://phillipwolf91.wordpress.com/2014/09/15/powershell-import-csv-to-sql-via-sqlbulkcopy/
.PARAMETER PeriodsToGet
Set number of recent periods to get the consumption details
.EXAMPLE
Azure\CostManagement.ps1
Azure\CostManagement.ps1 -PeriodsToGet 0
#>
# common parameters

param (
    $PeriodsToGet = 1
)

$ErrorActionPreference = 'Stop'

# Include functions
. '.\.include\func_sql.ps1'
. '.\.include\func_azcommon.ps1'

# $workingDir = '.\.assets\export\Billings'
[datetime]$earliestPeriod = '2019-08-01'

# Get credentials
try {
    $cred = Get-Secret 'Az' -ErrorAction Stop
} catch {
    $cred = Get-Credential -Message 'Provide db_owner AAD credentials'
}

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

# create connection string to database
$connStr = Resolve-ConnString -ServerInstance 'also-ecom.database.windows.net' -Database 'CONTROL' -Credential $cred
# delete processed periods from the table
$query = "delete from dbo.AzBillings where UsageStart >= '$($periodNames[0])';"
Invoke-SqlQuery -ConnectionString $connStr -Query $query

# Bulk copy object instantiation
$bulkCopy = New-Object('Microsoft.Data.SqlClient.SqlBulkCopy') $connStr
# Define the destination table
$bulkCopy.DestinationTableName = 'dbo.AzBillings'

$exportProps = ('Name', 'BillingPeriodName', 'ConsumedService', 'CostCenter', 'DepartmentName',
    'InstanceLocation', 'InstanceName', 'UsageQuantity', 'PretaxCost', 'Currency',
    'Product', 'SubscriptionName', 'UsageStart', 'InstanceId')

$subscriptions = Import-Csv -Path '.\.assets\config\Az\az_subscriptions.csv' | Select-Object -Property Name, Id

"`nGet billings for subscription:"
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    "`e[92m- ${sub.Name}`e[0m"
    foreach ($periodName in $periodNames) {
        "  `e[95m${periodName}`e[0m"
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
}
"`e[92m{0}`e[0m`n" -f 'Done!'
