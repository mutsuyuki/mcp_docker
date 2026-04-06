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

# Check if MCP_HOST_HOME is provided by the main run.sh
if [ -z "$MCP_HOST_HOME" ]; then
    echo "❌ Error: MCP_HOST_HOME is not set. Please check the main run.sh configuration." >&2
    exit 1
fi

# Path to the Unity MCP Relay binary on the host
RELAY_BIN="${MCP_HOST_HOME}/.unity/relay/unity-mcp-relay"

# Build docker run options
DOCKER_RUN_OPTS=(
    --rm
    --interactive
    --user="$(id -u):$(id -g)"
    --name="${CONTAINER_NAME}"
)

# 1. Mount ~/.unity (contains Relay binary and config)
DOCKER_RUN_OPTS+=(
    --mount="type=bind,src=${MCP_HOST_HOME}/.unity,dst=${MCP_HOST_HOME}/.unity"
)

# 2. Mount runtime directory (for Unix sockets on Linux)
if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=${XDG_RUNTIME_DIR},dst=${XDG_RUNTIME_DIR}"
    )
else
    FALLBACK_RUNTIME="/run/user/$(id -u)"
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=${FALLBACK_RUNTIME},dst=${FALLBACK_RUNTIME}"
    )
fi

# 3. Mount /tmp (Unity might create sockets in /tmp/unity-...)
DOCKER_RUN_OPTS+=(
    --mount="type=bind,src=/tmp,dst=/tmp"
)

# Mount workspace and use host network for TCP fallback
DOCKER_RUN_OPTS+=(
    --mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}"
    --workdir="${CONTAINER_WORKSPACE}"
    --net=host
)

# run
docker run "${DOCKER_RUN_OPTS[@]}" \
${IMAGE_FULLNAME} \
"$RELAY_BIN" "$@"
