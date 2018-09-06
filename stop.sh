docker rm $(docker ps -aq) -f 
docker network prune -f
docker volume prune -f 

