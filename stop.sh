docker network prune -f
docker volume prune -f 
docker rm $(docker ps -aq) -f 
