#!/bin/bash

SERVER_NAME=$(basename $(dirname $0))
IMAGE_FULLNAME="mcp_${SERVER_NAME}:latest"
CONTAINER_NAME="mcp_${SERVER_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="${MCP_CONTAINER_WORKSPACE:-$(pwd)/workspace}"

# build 
docker build \
--file $(dirname $0)/Dockerfile \
--progress=plain \
--tag  ${IMAGE_FULLNAME} \
.

# run
docker run \
--rm \
--interactive \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--mount="type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME}
