<#
.DESCRIPTION
https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-ver15&pivots=cs1-powershell
https://www.cathrinewilhelmsen.net/2018/12/02/sql-server-2019-docker-container/
https://hub.docker.com/_/microsoft-mssql-server
#>

docker pull mcr.microsoft.com/mssql/server:latest

docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=<!StrongPassword>" `
    -p 1433:1433 --name sql1 `
    -d mcr.microsoft.com/mssql/server:latest

# list all containers
docker ps -a

# manually start selected container
docker start sql1
docker stop sql1
# Start container on reboot
docker update --restart unless-stopped d49404e27b70

# create backup directory in container
docker exec -it sql1 mkdir /var/opt/mssql/backup

<#
https://docs.microsoft.com/en-us/sql/linux/tutorial-restore-backup-in-sql-server-container?view=sql-server-ver15
#>
$wwiUri = 'https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak'
$wwiLocation = 'D:\Instalki\MSDN\AdventureWorks\WorldWideImporters\WideWorldImporters-Full.bak'
$aw2017Location = 'D:\Instalki\MSDN\AdventureWorks\2017\AdventureWorks2017.bak'

Invoke-WebRequest -Uri $wwiUri -OutFile $wwiLocation

docker cp $wwiLocation sql1:/var/opt/mssql/backup
docker cp $aw2017Location sql1:/var/opt/mssql/backup

# list file in directory
docker exec sql1 ls /var/opt/mssql/backup
# remove file from container
docker exec sql1 rm -rf /var/opt/mssql/backup/WideWorldImporters-Full.bak
docker exec sql1 rm -rf /var/opt/mssql/backup/AdventureWorks2017.bak

# Delete specific container
docker rm f8cbadcea7cb

# List all docker images
docker images -a
# Remove selected image
docker rmi 3c7ee124fdd6

# remove any stopped containers and all unused images
docker system prune -a
