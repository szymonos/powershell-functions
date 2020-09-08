<#
.Synopsis
Script gets the configuration of builds, releases and repository policies from Azure DevOps and then uploads it to Azure storage table.
.Description
Azure DevOps Services REST API
https://docs.microsoft.com/en-us/rest/api/azure/devops/git/repositories/list?view=azure-devops-rest-5.1

Script requires Az module
https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az
Install-Module Az -AllowClobber
.Example
& 'Enumarate\enumAzureDevOps.ps1'
#>
Import-Module Az.Storage
# functions for Azure storage tables
. '.\.include\func_azcommon.ps1'
. '.\.include\func_azstorage.ps1'

# Retreive Azure DevOps token from Azure Key Vault
Connect-Subscription -Subscription '40911050-63d8-4d59-9d0e-f5f4f0e5a1d3' | Out-Null # ALSO IL DEV
$keyVault = 'also-devops-vault'
$token = (Get-AzKeyVaultSecret -VaultName $keyVault -Name 'AzPSToken').SecretValueText
# Basic authentication string
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($token, $token -join (':'))))

# Filters ?refs/heads/ from branch name
filter filterRef { $_ -replace '.{0,1}refs/heads/', '' }

# Define the storage account and context for Azure storage table
$StorageAccountName = 'alsodevopsstorage'
$storageAccountKey = (Get-AzKeyVaultSecret -VaultName $keyVault -Name $StorageAccountName).SecretValueText
$StorageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

<## BUILDS ##>
# Get list of builds
Write-Output "`nGETTING LIST OF BUILDS"
$uri = 'https://dev.azure.com/ALSO-ECom/InterLink/_apis/build/definitions?api-version=5.1'
$buildUrls = (Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value.url
Write-Output 'Processing build:'
# Azure table where results will be stored
$tableName = 'AzDoBuilds'
$table = Select-AzTable -TableName $tableName -StorageContext $StorageContext
# Clear table
Remove-AzTableRows -Table $table
$builds = @()
foreach ($url in $buildUrls) {
    $build = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get
    Write-Output ('- ' + $build.name)
    $partitionKey = $build.repository.defaultBranch | filterRef
    $rowKey = $build.id
    $prop = [ordered]@{
        BuildName        = $build.name;
        BuildPath        = ($build.path).Substring(1);
        BuildUrl         = $build.url;
        VariableGroups   = try { ($build.variableGroups | Where-Object { $_.type -eq 'AzureKeyVault' }).name } catch { $null };
        RepoId           = $build.repository.id;
        RepoName         = $build.repository.name;
        TriggerEnabled   = if (($build.triggers | Measure-Object).Count -gt 0) { $true } else { $false };
        TriggerFilter    = try { $build.triggers[0].branchFilters[0] | filterRef } catch { $null };
        TriggerType      = try { $build.triggers[0].triggerType } catch { $null };
        TriggerBatch     = try { $build.triggers[0].batchChanges } catch { $null };
        BuildPass        = try { $build.process.phases[0].steps[0].inputs.passwordBuild } catch { $null };
        PublishCondition = try { ($build.process.phases[0].steps | Where-Object { $_.displayName -eq 'Publish Artifact' }).condition } catch { $null }
    }
    $builds += New-Object psobject -Property @{ BuildId = $rowKey; BuildName = $prop.BuildName }
    Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
}


<## REPOSITORIES ##>
Write-Output "`nGETTING LIST OF REPOS"
$uri = 'https://dev.azure.com/ALSO-ECom/InterLink/_apis/git/repositories?api-version=5.1'
$repos = (Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value | `
    Select-Object -Property id, name, defaultBranch, size, webUrl
#$repos | Export-Csv -Path $csvRepos -NoTypeInformation -Encoding utf8
$tableName = 'AzDoRepos'
$table = Select-AzTable -TableName $tableName -StorageContext $StorageContext
# Clear table
Remove-AzTableRows -Table $table
foreach ($repo in $repos) {
    Write-Output ('- ' + $repo.name)
    $partitionKey = $repo.defaultBranch | filterRef
    $rowKey = $repo.id
    $prop = [ordered]@{
        RepoName = $repo.name;
        RepoSize = $repo.size;
        WebUrl   = $repo.webUrl;
    }
    Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
}

<## POLICIES ##>
# Azure table where results will be stored
$tableName = 'AzDoPolicies'
$table = Select-AzTable -TableName $tableName -StorageContext $StorageContext
# Clear table
Remove-AzTableRows -Table $table
# Get list of policies
Write-Output "`nGETTING LIST OF POLICIES"
$uri = 'https://dev.azure.com/ALSO-ECom/InterLink/_apis/policy/configurations?api-version=5.1'
$policiesFull = (Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value
Write-Output 'Processing repo:'
foreach ($repo in $repos) {
    $policiesRepo = $policiesFull | Where-Object { $_.settings.scope.repositoryId -eq $repo.id }
    Write-Output ('- ' + $repo.name)
    foreach ($policy in $policiesRepo) {
        $partitionKey = $policy.type.displayName
        $rowKey = $policy.id
        $prop = [ordered]@{
            RepoName      = $repo.Name;
            RepoId        = $repo.Id;
            BranchName    = try { $policy.settings.scope[0].refName | filterRef } catch { $null };
            IsEnabled     = $policy.isEnabled;
            ApproverCount = $policy.settings.minimumApproverCount;
            Build         = if ($policy.type.displayName -eq 'Build') { ($builds | Where-Object { $_.BuildId -eq $policy.settings.buildDefinitionId }).BuildName };
        }
        Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
    }
}


<## RELEASES ##>
# Azure table where results will be stored
$tableName = 'AzDoReleases'
$table = Select-AzTable -TableName $tableName -StorageContext $StorageContext
# Clear table
Remove-AzTableRows -Table $table
# Get list of releases
Write-Output "`nGETTING LIST OF RELEASES"
$uri = 'https://vsrm.dev.azure.com/ALSO-ECom/InterLink/_apis/release/definitions?api-version=5.1'
$releaseUrls = (Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get).value.url
Write-Output 'Processing release:'
foreach ($url in $releaseUrls) {
    #$url = 'https://vsrm.dev.azure.com/ALSO-ECom/30021109-8a22-4ff9-82f3-858f5e4639e9/_apis/Release/definitions/18'
    $release = Invoke-RestMethod -Uri $url -Headers @{ Authorization = "Basic $base64AuthInfo" } -Method Get
    Write-Output ('- ' + $release.name)
    $rgTasks = $release.environments.deployPhases.workflowTasks | Where-Object { $_.taskId -eq 'c1177c17-3934-4005-ba89-a4549fe4f0a1' }
    $partitionKey = $release.isDeleted
    $rowKey = $release.id
    $prop = [ordered]@{
        ReleaseName     = $release.name;
        ReleasePath     = ($release.path).Substring(1);
        VariableGroups  = try { $release.variableGroups[0] } catch { $null };
        VariableDB      = try { $release.variables.DatabaseName.value } catch { $null };
        VariableServer  = try { $release.variables.ServerName.value } catch { $null };
        ArtifactType    = try { $release.artifacts[0].type } catch { $null };
        ArtifactName    = try { ($builds | Where-Object { $_.BuildId -eq $release.artifacts[0].definitionReference.definition.id }).BuildName } catch { $null };
        ArtifactAlias   = try { $release.artifacts[0].alias } catch { $null };
        TriggerEnabled  = if (($release.triggers | Measure-Object).Count -gt 0) { $true } else { $false };
        TriggerType     = try { $release.triggers[0].triggerType } catch { $null };
        TriggerArtifact = try { $release.triggers[0].artifactAlias } catch { $null };
        TriggerBranch   = try { $release.triggers[0].triggerConditions[0].sourceBranch } catch { $null };
        CreatePass      = try { $rgTasks[0].inputs.TargetDatabasePassword } catch { $null };
        CreateServer    = try { $rgTasks[0].inputs.TargetDatabaseServer } catch { $null };
        CreateDatabase  = try { $rgTasks[0].inputs.TargetDatabaseName } catch { $null };
        CompareOptions  = try { $rgTasks[0].inputs.SqlCompareOptions } catch { $null };
        DeployPass      = try { $rgTasks[1].inputs.TargetDatabasePassword } catch { $null };
        DeployServer    = try { $rgTasks[1].inputs.TargetDatabaseServer } catch { $null };
        DeployDatabase  = try { $rgTasks[1].inputs.TargetDatabaseName } catch { $null };
    }
    Add-AzTableRow -Table $table -PartitionKey $partitionKey -RowKey $rowKey -Property $prop
}
