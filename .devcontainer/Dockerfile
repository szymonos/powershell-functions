# Find the Dockerfile for mcr.microsoft.com/azure-functions/powershell:3.0-powershell${VARIANT}-core-tools at this URL
# https://github.com/Azure/azure-functions-docker/blob/master/host/3.0/buster/amd64/powershell

# Update the VARIANT arg in devcontainer.json to pick a supported PowerShell version: 7, 6
ARG VARIANT=7
FROM mcr.microsoft.com/azure-functions/powershell:3.0-powershell${VARIANT}-core-tools

# Install PowerShell modules
SHELL ["/usr/bin/pwsh", "-c"]
RUN $ErrorActionPreference='Stop'; \
    Start-Transcript -Path /Dockerfile.log -Append -IncludeInvocationHeader; \
    $PSVersionTable | Write-Output; \
    Install-Module posh-git -AllowPrerelease -Force; \
    Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease; \
    New-Item /root/.config/powershell/ -Type Directory -Force; \
    Stop-Transcript;

# Copy pwsh profile
COPY src/profile.ps1 /opt/microsoft/powershell/7/
COPY src/.zshrc /root/

# Default commands to pwsh
ENTRYPOINT ["pwsh","-c"]
