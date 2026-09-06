#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_PROJECT_ROOT="${MCP_HOST_PROJECT_ROOT:-${PROJECT_ROOT}}"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-${HOST_PROJECT_ROOT}/workspace}"
CONTAINER_WORKSPACE="/workspace"

# Build. Build output goes to stderr: stdout is the MCP stdio channel.
# The user must match the host's so that $HOME resolves to the same path the
# relay's bridge files are mounted under.
docker build \
--file "${SCRIPT_DIR}/Dockerfile" \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag "${IMAGE_FULLNAME}" \
"${SCRIPT_DIR}" >&2

# If the first argument is --build-only, exit after building.
if [ "$1" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# Check if MCP_HOST_HOME is provided by the main DockerRun.sh
if [ -z "$MCP_HOST_HOME" ]; then
    echo "❌ Error: MCP_HOST_HOME is not set. Please check the main DockerRun.sh configuration." >&2
    exit 1
fi

# Path to the Unity MCP Relay binary on the host
RELAY_BIN="${MCP_HOST_HOME}/.unity/relay/relay_linux"

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
"${IMAGE_FULLNAME}" \
"$RELAY_BIN" "$@"
