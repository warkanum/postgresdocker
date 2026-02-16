#!/bin/sh
# Usage: ./docker_build.sh [dockername]
# If no dockername is provided, defaults to 'pgsql18'

DOCKERNAME=${1:-pgsql18}

# Load environment variables including DOCKER_UID and DOCKER_GID
. ./.env

echo "Building and running Docker container: $DOCKERNAME"

docker build . -t warkypublic/$DOCKERNAME
docker stop $DOCKERNAME
docker rm $DOCKERNAME
mkdir -p /tmp/pgsql18_data
docker run -d -p 5403:5432 --shm-size=8g -v /tmp/pgsql18_data:/var/lib/postgresql --env-file ./.env --name $DOCKERNAME --restart unless-stopped --memory=10G --cpus=4  warkypublic/$DOCKERNAME


