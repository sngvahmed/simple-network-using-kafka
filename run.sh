source .env
bash generate.sh

docker-compose -f docker.yaml up
