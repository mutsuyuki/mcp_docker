#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"

# build with username argument
docker build \
--progress=plain \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag  ${IMAGE_FULLNAME} \
${SCRIPT_DIR}

# If the first argument is --build-only, exit after building.
if [ "$1" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# run with network host for TCP communication
docker run \
--rm \
--interactive \
--net=host \
--user="$(id -u):$(id -g)" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME}