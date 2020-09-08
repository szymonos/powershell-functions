<#
.DESCRIPTION
Set-AzContext -SubscriptionId '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3';   # ALSO IL DEV
Set-AzContext -SubscriptionId 'f37a52e7-fafe-401f-b7dd-fc50ea03fcfa';   # ALSO IL QA
Set-AzContext -SubscriptionId '4933eec9-928e-4cca-8ce3-8f0ea0928d36';   # ALSO IL PROD
https://docs.microsoft.com/en-us/powershell/module/az.resources/get-azresource
.EXAMPLE
.temp\AzResource.ps1
#>
$subs = Import-Csv -Path '.\.assets\config\Az\az_subscriptions.csv'
Write-Output ('Get resources in subscription:')
foreach ($sub in $subs) {
    Write-Output ('- ' + $sub.Name)
    Set-AzContext -Subscription $sub.Id | Out-Null
    Get-AzResource | Select-Object -Property ResourceName `
        , @{Name = 'Subscription'; Expression = { $sub.Name } } `
        , @{Name = 'ResourceType'; Expression = { $_.ResourceType -replace ('Microsoft.', '') } } `
        , Kind `
        , Location `
        , ParentResource `
        , ResourceGroupName `
        , @{Name = 'Tags'; Expression = {
            $tags = foreach ($key in $_.Tags.Keys) {
                if ([string]::IsNullOrEmpty($_.Tags.Item($key)) -eq $false -and $key -notlike 'hidden-*') {
                    $key, $_.Tags.Item($key) -join (':')
                }
            }
            $tags -join ('; ')
        }
    } | Export-Csv -Path ".\.assets\export\enumAzResources_($($sub.Name)).csv" -NoTypeInformation -Encoding utf8
}
