#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="${MCP_CONTAINER_WORKSPACE:-$(pwd)/workspace}"

# build 
docker build \
--file $(dirname $0)/Dockerfile \
--progress=plain \
--tag  ${IMAGE_FULLNAME} \
${SCRIPT_DIR}

# run
docker run \
--rm \
--interactive \
--user="$(id -u):$(id -g)" \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME} \
${CONTAINER_WORKSPACE}