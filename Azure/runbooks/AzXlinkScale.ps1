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
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

## Convert UTC to CET
$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time')
$UTC = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$CET = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TZ)
# Get day of the week
$dayOfWeek = (Get-Date).DayOfWeek.value__

# Check if it is working day between 09:00 and 17:00
$reqSvc = if ($dayOfWeek -in 1..5 -and $CET.Hour -in 4..10) {
    Write-Output 'HS_Gen5_14'
} else {
    Write-Output 'HS_Gen5_4'
}
Write-Output ('Day of week: ' + $dayOfWeek + ' | Time: ' + $CET.ToString('yyyy-MM-dd HH:mm:ss'))

#Parameters
$resourceGroupName = 'Also-Ecom-PROD'
$serverName = 'also-ecom'
$databaseName = 'XLINK'
$licenseType = 'BasePrice'

[bool]$doScale = $false
$dbProp = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName | Select-Object -Property DatabaseName, CurrentServiceObjectiveName
if ($dbProp.CurrentServiceObjectiveName -ne $reqSvc) {
    $doScale = $true
}

if ($doScale) {
    $scaleCmd = { Set-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -RequestedServiceObjectiveName $reqSvc -LicenseType $licenseType -ReadReplicaCount 1 }
    Write-Output ('Scaling database to: ' + $reqSvc)
    $scaleExec = Measure-Command { & $scaleCmd }
    Write-Output $scaleExec.ToString('hh\:mm\:ss\.fff')
} else {
    Write-Output ('Scaling not required')
}
