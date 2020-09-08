$dbRepos = (Get-ChildItem -Path 'C:\Source\Repos' -Filter '*database' -Directory | Where-Object -Property Name -ne 'AC Database').Name
$fn2Add = 'C:\Source\Git\SQL\Azure\AdminSolutions\dbo.fn_ms2Time.sql', `
    'C:\Source\Git\SQL\Azure\AdminSolutions\dbo.fn_XEErrorInfoReader.sql', `
    'C:\Source\Git\SQL\Azure\AdminSolutions\dbo.fn_GetIndexesDefinition.sql'
$sp2Add = 'C:\Source\Git\SQL\Azure\AdminSolutions\dbo.sp_PrintTimeDiff.sql', `
    'C:\Source\Git\SQL\Azure\AdminSolutions\dbo.sp_CreateTable.sql'

# create branch and commit changes
foreach ($repo in $dbRepos) {
    #$repo = $dbRepos[6]
    [System.Console]::WriteLine("`e[95m{0}", $repo)
    Set-Location $repo
    git checkout master
    git pull
    if (!(Test-Path '.\Functions')) { New-Item 'Functions' -ItemType Directory }
    Copy-Item -Path $fn2Add -Destination '.\Functions\' -Force
    if (!(Test-Path '.\Stored Procedures')) { New-Item 'Stored Procedures' -ItemType Directory }
    Copy-Item -Path $sp2Add -Destination '.\Stored Procedures\' -Force
    git checkout -b azure-pipelines
    git add .
    git commit -m 'Set up CI with Azure Pipelines'
    git push -u origin head
    git checkout master
}

# update branch and commit changes
foreach ($repo in $dbRepos) {
    [System.Console]::WriteLine("`e[95m{0}`e[0m", $repo)
    Set-Location $repo
    git checkout azure-pipelines
    git pull
    Copy-Item -Path $fn2Add -Destination '.\Functions' -Force
    Copy-Item -Path $sp2Add -Destination '.\Stored Procedures' -Force
    git add .
    git commit -m 'Admin scripts fix'
    git push -u origin head
    git checkout master
}
