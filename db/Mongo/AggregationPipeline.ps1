$db = Get-AzureRmResource -ResourceName "CosmosDB account name" -ResourceGroupName "RG name" | Where-Object -Property ResourceType -eq "Microsoft.DocumentDb/databaseAccounts"

# Enable some optional capabilities/features
$props = @{capabilities = @( @{name="EnableAggregationPipeline"}, @{name="MongoDBv3.4"})}

# Patch the resource with these settings
Set-AzureRmResource -ResourceId $db.ResourceId -ApiVersion "2015-04-08" -PropertyObject $props -UsePatchSemantics
