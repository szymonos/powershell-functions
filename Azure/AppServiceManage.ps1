<#
.Description
Set-AzContext -Subscription 'ALSO IL DEV' | Out-Null
Set-AzContext -Subscription 'ALSO IL QA' | Out-Null
Set-AzContext -Subscription 'ALSO IL PROD' | Out-Null
.Example
#>

# Variables
$resourceGroup = 'Also-AppServices-DEV'

## Get all web apps
$allApps = Get-AzWebApp; $allApps | Select-Object -Property ResourceGroup, Name
$allApps = Get-AzWebApp -ResourceGroupName $resourceGroup; $allApps | Select-Object -Property ResourceGroup, Name
$allApps | Where-Object -Property Name -eq 'ecom-sapfunctions-service-prod' | Select-Object -Property *
# Save enumerated apps to CSV
$allApps | Select-Object -Property ResourceGroup, Name, Kind | Export-Csv '.\.assets\enum\enumAzApps.csv' -NoTypeInformation

# Get app settings
$appName = 'InterlinkAdmin-dev'
Get-AzWebApp -Name $appName
Get-AzWebApp -ResourceGroupName $resourceGroup -Name $appName
(Get-AzWebApp -Name $appName).SiteConfig.AppSettings

# Get all app settings in all apps
$allAppsCfg = @(); $appCnt = $allApps.Count; $i=1
foreach ($app in $allApps) {
    ("$i / $appCnt - $($app.Name)"); $i++
    $allAppsCfg += Get-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name | `
        Select-Object -Property ResourceGroup, Name, SiteConfig `
        , @{Name = 'AzureWebJobsStorage'; Expression = { ($_.SiteConfig.AppSettings | Where-Object -Property Name -eq 'AzureWebJobsStorage').Value } }
}

# search for specific storage accounts defined in app settings
$allAppsCfg | Where-Object -Property AzureWebJobsStorage -Like '*storageaccountalsoe8620*' | Select-Object ResourceGroup, Name

# search for specific app setting
$fndString = '*Customer*'; $allAppsCfg | Where-Object { $_.SiteConfig.AppSettings.Name -like $fndString } | Select-Object -Property Name, ResourceGroup
$fndString = '*PaymentApi*'; $allAppsCfg | Where-Object { $_.SiteConfig.AppSettings.Name -like $fndString } | ForEach-Object {
    $appSettings = $_.SiteConfig.AppSettings | Where-Object -Property Name -like $fndString
    foreach ($appSet in $appSettings) {
        [PSCustomObject]@{
            ResourceName = $_.Name
            ResourceGroup = $_.ResourceGroup
            SettingName = $appSet.Name
            SettingValue = $appSet.Value
        }
    }
}

# show app settings for specific application
($allAppsCfg | Where-Object -Property Name -eq 'alsobladmin').SiteConfig.AppSettings

## App Service Plan ##
# Get all App service plans in subscription
Get-AzAppServicePlan | Select-Object Name, ResourceGroup, NumberOfSites, MaximumNumberOfWorkers

# get App service plan details
$resourceGroup = 'Also-AppServices-DEV'
$svcPlanName = 'ASP-AlsoIL-Dev'
$appSvcPlan = Get-AzAppServicePlan -ResourceGroupName $resourceGroup -Name $svcPlanName; $appSvcPlan

# change app service plan settings
Set-AzAppServicePlan -ResourceGroupName $resourceGroup -Name $svcPlanName -PerSiteScaling $true

# get all app services in plan
Get-AzWebApp -AppServicePlan $appSvcPlan | Select-Object Name, ResourceGroup, State, Kind

# change plan for existing App Service
Set-AzWebApp -ResourceGroupName 'ALSO-AUTHSVC-PROD' -Name 'also-ecomphotoservices-prod' -AppServicePlan 'also-authsvc-serviceplan-prod'
