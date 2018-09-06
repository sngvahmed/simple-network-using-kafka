source .env
bash generate.sh

docker-compose -f docker-kafka.yml up
