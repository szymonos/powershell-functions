<#
.SYNOPSIS
Docker Swarm
.LINK
https://docs.docker.com/engine/swarm
.EXAMPLE
Docker\DockerSwarm.ps1
#>

param(
    [switch]$run
)
docker version
if($run){
    ## Initialize swarm
    docker swarm init --advertise-addr=192.168.65.3 --listen-addr 192.168.65.3:2377
    ## manage nodes
    # get command with token for joining manager to swarm
    docker swarm join-token manager
    # get command with token for joining worker to swarm
    docker swarm join-token worker
    # list swarm nodes
    docker node ls
    # promote node to swarm manager
    docker node promote 2177x8kp5t2r0fjv48khfy106
    # demote node to swarm worker
    docker node demote m5eekplkmx5erk78t498r3vvo
    # list tasks on specific node
    docker node ps dockert2

    ## manage services
    # list swarm services
    docker service ls
    docker node ps self
    # create service http://localhost/tutorial/
    docker service create --name tutorial -p 80:80 docker101tutorial
    docker service create --name tutorial -p 8080:80 --replicas 3 docker101tutorial
    docker service create --name psight2 --network ps-net -p 8080:80 --replicas 3 nigelpoulton/tu-demo:v1
    # update service
    docker service update --image nigelpoulton/tu-demo:v2 --update-parallelism 2 --update-delay 10s psight2

    # query service
    docker service ps tutorial
    docker service ps psight2
    docker service ps psight2 | grep :v2
    # inspect service
    docker service inspect tutorial
    docker service inspect psight2
    docker service inspect --pretty psight2

    # remove servie
    docker service rm tutorial

    # scale service
    docker service scale tutorial=3
    docker service update --replicas 5 tutorial

    # leave docker swarm
    docker swarm leave --force

    ## network
    # list networks
    docker network ls
    # add overlay network
    docker network create -d overlay tt-net
    docker network create -d overlay ps-net

    docker network remove tt-net

    # Stacks and Dabs
    git clone https://github.com/dockersamples/example-voting-app.git
}
