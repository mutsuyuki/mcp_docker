#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_PROJECT_ROOT="${MCP_HOST_PROJECT_ROOT:-${PROJECT_ROOT}}"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-${HOST_PROJECT_ROOT}/workspace}"
CONTAINER_WORKSPACE="/workspace"

# build with username argument
docker build \
--file "${SCRIPT_DIR}/Dockerfile" \
--progress=plain \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag "${IMAGE_FULLNAME}" \
"${SCRIPT_DIR}"

# If the first argument is --build-only, exit after building.
if [ "$1" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# run with network host for TCP communication
DOCKER_RUN_OPTS=(
    --rm
    --interactive
    --net=host
    --user="$(id -u):$(id -g)"
    --mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}"
    --mount="type=bind,src=/tmp,dst=/tmp"
    --workdir="${CONTAINER_WORKSPACE}"
    --name="${CONTAINER_NAME}"
)

# mDNS (.local) resolution via host avahi-daemon socket
if [ -e "/var/run/avahi-daemon/socket" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/var/run/avahi-daemon/socket,dst=/var/run/avahi-daemon/socket"
    )
fi

docker run "${DOCKER_RUN_OPTS[@]}" "${IMAGE_FULLNAME}"
