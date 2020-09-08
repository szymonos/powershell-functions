<#
.SYNOPSIS
Prep Windows for containers
.LINK
https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=Windows-Server
#>

# Install the Docker-Microsoft PackageManagement Provider
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force

# Use the PackageManagement PowerShell module to install the latest version of Docker.
Install-Package -Name docker -ProviderName DockerMsftProvider

# Restart-Computer -Force

# install base image
docker pull mcr.microsoft.com/windows/servercore:ltsc2019
docker pull mcr.microsoft.com/dotnet/framework/sdk:latest

docker images

# tag image as latest
docker tag 48 servercore:latest

docker run -it windowsservercore cmd
# Leave interactive shell in conteiner but keep it running
# CTRL-PQ
# list containers
docker ps

# untag image
docker rmi servercore
