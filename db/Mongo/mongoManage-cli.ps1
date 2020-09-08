<#
.Example
C:\Source\Git\DevOps\cli\mongoManage.ps1
#>

# login to subscription
az login

# list available subscriptions
az account list --output table

# show current subscription
az account show --output table

# change subscription
az account set --subscription 'ALSO IL DEV'
az account set --subscription 'ALSO IL QA'
az account set --subscription 'ALSO IL PROD'


# az cosmosdb update -n { acc } -g { rg } --capabilities EnableAggregationPipeline
az cosmosdb show --name 'also-searchservice-cosmos-dev' --resource-group 'Also-SearchService-DEV' | ConvertFrom-Json

az cosmosdb update --capabilities 'EnableAggregationPipeline' --name 'also-searchservice-cosmos-dev' --resource-group 'Also-SearchService-DEV'
