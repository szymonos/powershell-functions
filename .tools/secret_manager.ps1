<#
.SYNOPSIS
The Secret Manager tool operates on project-specific configuration settings stored in your user profile.
.LINK
https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-3.1&tabs=windows#secret-manager
#>
# go to directory in which the .csproj file exists
Set-Location .\MyProject

# Enable secret storage
dotnet user-secrets init

# Set a secret
dotnet user-secrets set "Movies:ServiceApiKey" "12345"
dotnet user-secrets set "Movies:ServiceApiKey" "12345" --project "C:\apps\WebApp1\src\WebApp1"

# Set multiple secrets
Get-Content .\input.json | dotnet user-secrets set

# List the secrets
dotnet user-secrets list

# Remove a single secret
dotnet user-secrets remove "Movies:ConnectionString"

# Remove all secrets
dotnet user-secrets clear
