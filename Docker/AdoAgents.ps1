<#
.SYNOPSIS
Install ADO Pipeline Agent in Docker and configure Dockre Swarm
.LINK
https://cloudconfusion.co.uk/JFDI-guide-to-ADO-Agent-in-Docker-Swarm/
https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops
https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container?view=vs-2019
.EXAMPLE
Docker\AdoAgents.ps1
#>

$azpURL = 'https://dev.azure.com/ALSO-ECom'
$azpToken = (Get-AzKeyVaultSecret -VaultName 'also-devops-vault' -Name 'AzpToken').SecretValueText

# Initialize Docker Swarm
Get-NetIPAddress -AddressFamily IPv4 | Format-Table -AutoSize -Property PrefixOrigin, InterfaceIndex, InterfaceAlias, IPAddress, PrefixLength
docker swarm init --advertise-addr=192.168.43.37 --listen-addr 192.168.43.37:2377

# Create ADOAgent
docker service create --name=ADOAgent --endpoint-mode dnsrr -e AZP_URL=$azpURL -e AZP_TOKEN=$azpToken -e AZP_AGENT_NAME=DockerContainerAgent dockeragent

# docker service list
docker service list
docker service ps t6

# remove service
docker service rm ch

# Leave docker swarm
docker swarm leave --force
