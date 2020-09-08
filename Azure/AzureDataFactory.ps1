<#
.SYNOPSIS
Wyświetla historię wykonania pipeline'a
.DESCRIPTION
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
.PARAMETER CurrentlyRunning
Wyświetla wszystkie aktualnie uruchomione pipeline'y
.PARAMETER ShowTriggers
Wyświetla wszystkie triggery w ADFie
.PARAMETER PipeLineName
Nazwa pipeline'a, którego historię ma zwrócić skrypt
.PARAMETER DaysToDisplay
Liczba dni historii do wyświetlenia, domyślnie 3
.EXAMPLE
Azure\AzureDataFactory.ps1 -CurrentlyRunning
Azure\AzureDataFactory.ps1 -ShowTriggers
Azure\AzureDataFactory.ps1 -PipelineName 'HierarchyMasterToInterLinkPipeline'
Azure\AzureDataFactory.ps1 -PipelineName 'OrdersMasterPipeline'
Azure\AzureDataFactory.ps1 -PipelineName 'OrdersMasterToBusPipeline'
Azure\AzureDataFactory.ps1 -PipelineName 'ProductMasterControlPipeline' -DaysToDisplay 7
#>

param (
    [parameter(ParameterSetName='Running')][switch]$CurrentlyRunning,
    [parameter(ParameterSetName='Triggers')][switch]$ShowTriggers,
    [parameter(ParameterSetName='Pipeline')][string]$PipelineName,
    [parameter(ParameterSetName='Pipeline')][int]$DaysToDisplay = 3
)
. '.include\func_azcommon.ps1';
Connect-Subscription -Subscription '4933eec9-928e-4cca-8ce3-8f0ea0928d36' | Out-Null    # ALSO IL PROD

# parameters
$resourceGroupName = 'Also-EcomDF-PROD'
$dataFactoryName = 'also-ecomdf-def'
$subscriptionId = '4933eec9-928e-4cca-8ce3-8f0ea0928d36'

if ($PipelineName) {
    Set-AzContext -SubscriptionId $subscriptionId | Out-Null
    $lastUpdatedAfter = (Get-Date).AddDays(-$DaysToDisplay)
    Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName -PipelineName $PipelineName -LastUpdatedAfter $lastUpdatedAfter -LastUpdatedBefore (Get-Date) | `
        Sort-Object -Property LastUpdated | `
        Select-Object Status `
        , @{Name = 'LastUpdated'; Expression = { [System.TimeZoneInfo]::ConvertTimeFromUtc($_.LastUpdated, ([System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time'))) } } `
        , @{Name = 'Duration'; Expression = { (New-TimeSpan -Start $_.RunStart -End $_.RunEnd).ToString('hh\:mm\:ss\.fff') } } `
        , Message
}

if ($ShowTriggers) {
    $adfTriggers = Get-AzDataFactoryV2Trigger -ResourceGroupName $resourceGroupName -DataFactoryName $dataFactoryName
    $ret = $adfTriggers | Select-Object -Property Name, RuntimeState, ETag
    return $ret
}

if ($CurrentlyRunning) {
    $pipelinesInProgress = Get-AzDataFactoryV2PipelineRun -ResourceGroupName $resourceGroupName `
        -DataFactoryName $dataFactoryName `
        -LastUpdatedAfter (Get-Date).ToString('yyyy-MM-dd') `
        -LastUpdatedBefore (Get-Date) | `
        Where-Object -Property Status -eq 'InProgress' | `
        Select-Object PipelineName, Status `
        , @{Name = 'RunStart'; Expression = { [System.TimeZoneInfo]::ConvertTimeFromUtc($_.RunStart, ([System.TimeZoneInfo]::FindSystemTimeZoneById('Central European Standard Time'))) } } `
        , @{Name = 'Duration'; Expression = { (New-TimeSpan -Start $_.RunStart -End ([System.DateTime]::UtcNow)).ToString('hh\:mm\:ss\.fff') } }
    return $pipelinesInProgress
}
