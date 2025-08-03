#!/bin/bash

SERVER_NAME=$(basename $(dirname $0))
IMAGE_FULLNAME="mcp_${SERVER_NAME}:latest"
CONTAINER_NAME="mcp_${SERVER_NAME}_$(date "+%Y_%m%d_%H%M%S")"

# build with username argument
docker build \
--progress=plain \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag  ${IMAGE_FULLNAME} \
.

# run with network host for TCP communication
docker run \
--rm \
--interactive \
--net=host \
--user="$(id -u):$(id -g)" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME}