## Getting Started tutorial from Docker

cd /mnt/h/Source/Repos/GitHub/getting-started/

# clone getting started repo
git clone https://github.com/docker/getting-started.git

cd getting-started

# build image
docker build -t docker101tutorial .

# run container
docker run -d -p 8080:80 --name docker-tutorial docker101tutorial

# stop container
docker stop docker-tutorial

# start container
docker container start docker-tutorial

# tag and push container to docker gallery
docker tag docker101tutorial muscimol/docker101tutorial
docker push muscimol/docker101tutorial

# Open tutorial
http://localhost/tutorial/

# list containers
docker ps    # list running containers
docker ps -a # list all containers
# attach shell to selected container
docker exec -it 87 /bin/sh

## hello-world
docker run hello-world

# run third party container in detached mode (run in background, don't write to terminal)
docker run -d --name web -p 80:8080 nigelpulton/pluralsight-docker-ci

docker pull ubuntu
docker run -it ubuntu /bin/sh

docker ps
docker ps -a
docker ps -a -f status=exited
docker rm (docker ps -aq -f status=exited)
docker images
docker stop 3c569d0b815d
