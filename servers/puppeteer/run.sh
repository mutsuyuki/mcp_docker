#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="/workspace"

# build 
docker build \
--file $(dirname $0)/Dockerfile \
--progress=plain \
--tag  ${IMAGE_FULLNAME} \
${SCRIPT_DIR}

# If the first argument is --build-only, exit after building.
if [ "$1" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# allow display connection for GUI
xhost +

# run with GUI support
docker run \
--rm \
--interactive \
--user="$(id -u):$(id -g)" \
--shm-size="2g" \
--env="QT_X11_NO_MITSHM=1" \
--env="DISPLAY=${DISPLAY}" \
--env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
--env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
--env="PULSE_SERVER=${PULSE_SERVER}" \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--mount="type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly" \
--mount="type=bind,src=/run/dbus/system_bus_socket,dst=/run/dbus/system_bus_socket" \
--workdir="${CONTAINER_WORKSPACE}" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME}