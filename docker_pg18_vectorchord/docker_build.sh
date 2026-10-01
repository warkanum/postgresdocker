#!/bin/sh
# Usage: ./docker_build.sh [dockername]
# If no dockername is provided, defaults to 'pgsql18vc'

DOCKERNAME=${1:-pgsql18vc}

# Load environment variables including DOCKER_UID and DOCKER_GID
. ./.env

echo "Building and running Docker container: $DOCKERNAME"

docker build --build-arg DOCKER_UID=${DOCKER_UID:-1000} --build-arg DOCKER_GID=${DOCKER_GID:-1000} -t warkypublic/$DOCKERNAME .
docker stop $DOCKERNAME
docker rm $DOCKERNAME
mkdir -p /tmp/pgsql18vc_data
docker run -d -p 5403:5432 --shm-size=8g -v /tmp/pgsql18vc_data:/var/lib/postgresql --env-file ./.env --name $DOCKERNAME --restart unless-stopped --memory=10G --cpus=4  warkypublic/$DOCKERNAME


