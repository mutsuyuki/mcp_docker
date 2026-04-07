#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="/workspace"

# build
docker build \
--file "${SCRIPT_DIR}/Dockerfile" \
--progress=plain \
--tag "${IMAGE_FULLNAME}" \
"${SCRIPT_DIR}"

# If the first argument is --build-only, exit after building.
if [ "$1" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# run
docker run \
--rm \
--interactive \
--user="$(id -u):$(id -g)" \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--workdir="${CONTAINER_WORKSPACE}" \
--name="${CONTAINER_NAME}" \
"${IMAGE_FULLNAME}" \
--db-path "${CONTAINER_WORKSPACE}/database.db"