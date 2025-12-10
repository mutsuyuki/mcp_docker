#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="/workspace"

# build with username argument
docker build \
--file $(dirname $0)/Dockerfile \
--progress=plain \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag  ${IMAGE_FULLNAME} \
${SCRIPT_DIR} 

# allow display connection for GUI
xhost +

# run with GUI support and network host
docker run \
--rm \
--interactive \
--tty \
--user="$(id -u):$(id -g)" \
\
--gpus=all \
--net=host \
--shm-size="2g" \
\
--env="NVIDIA_VISIBLE_DEVICES=all" \
--env="NVIDIA_DRIVER_CAPABILITIES=all" \
--env="__GLX_VENDOR_LIBRARY_NAME=nvidia" \
--env="QT_X11_NO_MITSHM=1" \
--env="DISPLAY=${DISPLAY}" \
--env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
--env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
--env="PULSE_SERVER=${PULSE_SERVER}" \
\
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--mount="type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly" \
--mount="type=bind,src=${XDG_RUNTIME_DIR}/pulse,dst=${XDG_RUNTIME_DIR}/pulse" \
\
--workdir="${CONTAINER_WORKSPACE}" \
\
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME}

echo "🎯 Blender GUI container started: ${CONTAINER_NAME}"
echo "📊 Check status: docker logs ${CONTAINER_NAME}"
echo "🔌 TCP Server: Listening on localhost:9876"