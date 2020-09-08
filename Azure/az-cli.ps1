# login to subscription
az login

# list available subscriptions
az account list --output table

# show current account detail
az account show | ConvertFrom-Json

# change subscription
az account set --subscription "40911050-63d8-4d59-9d0e-f5f4f0e5a1d3"  # ALSO IL DEV
az account set --subscription "f37a52e7-fafe-401f-b7dd-fc50ea03fcfa"  # ALSO IL QA
az account set --subscription "4933eec9-928e-4cca-8ce3-8f0ea0928d36"  # ALSO IL PROD
az account set --subscription "ab5d3bac-0dbe-4754-9c81-7f0827f1ae9c"  # ALSO IS GmbH - Cloud BI (Converted to EA)

# Create service principal
az ad sp create-for-rbac -n "postmanprodsvc"

# https://docs.microsoft.com/en-us/cli/azure/functionapp/config?view=azure-cli-latest#az-functionapp-config-set
# Show settings for a function app.
az functionapp config appsettings list --name "also-cdp-dev" --resource-group "CustomerDataPlatformRG"

# Get the details of a function app's configuration.
az functionapp config show --name "also-cdp-dev" --resource-group "CustomerDataPlatformRG" | ConvertFrom-Json
az functionapp config show --name "also-cdp" --resource-group "CustomerDataPlatformRG" | ConvertFrom-Json

# Set the function app's configuration.
# !Run in cmd becasause of '|' in parameter value
az functionapp config set --linux-fx-version "PYTHON|3.8" --name "also-cdp-dev" --resource-group "CustomerDataPlatformRG"
