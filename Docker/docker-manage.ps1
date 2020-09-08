<#
.SYNOPSIS
Docker management commands
#>

<## CONTAINERS ##>
# list all containers
docker ps -a
docker ps -a --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}"
$cntrName = (docker ps -a --format "{{.Names}}")[1]

# Stop all docker containers
docker stop $(docker ps -a -q)
# Delete docker containers
docker rm $(docker ps -a -q)    # all containers
docker rm $cntrName          # selected container

# start/stop container
docker start $cntrName
docker stop $cntrName
# Start container on reboot
docker update --restart unless-stopped $cntrName

<## EXECUTE COMMANDS IN CONTAINER ##>
# copy file to container
docker cp 'C:\temp\Api.pdf' sql1:/var/opt/mssql/backup
# list file in directory
docker exec $cntrName ls
# remove file from container
docker exec $cntrName rm -rf /var/opt/mssql/backup/WideWorldImporters-Full.bak

<## attach shell  ##>
docker exec -it $cntrName /bin/bash

<## IMAGES ##
https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes
#>
# List all docker images
docker images -a
docker image ls

# tag image as latest
docker tag 48 servercore:latest

# run image in interactive mode
docker run -it mcr.microsoft.com/mssql/server pwsh
docker run -it mcr.microsoft.com/mssql/server cmd
docker run -it ubuntu /bin/bash

# Remove selected image
docker rmi 3c7ee124fdd6
## remove any stopped containers and all unused images
docker system prune -a

<##  MOVE WINDOWS CONTAINERS TO OTHER LOCATION ##
Get-Service docker
Get-Service docker | Stop-Service

Edit C:\ProgramData\Docker\config\daemon.json and add data-root setting
{
  "registry-mirrors": [],
  "insecure-registries": [],
  "debug": true,
  "experimental": false,
  "storage-opts": ["size=127GB"],
  "data-root": "d:/ProgramData/Docker"
}

Restart-Service docker
#>
