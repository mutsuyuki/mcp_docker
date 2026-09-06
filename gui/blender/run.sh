#!/bin/bash
set -e
HOST_OS_TYPE=$(uname -s)
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_gui_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_gui_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
HOST_PROJECT_ROOT="${MCP_HOST_PROJECT_ROOT:-${PROJECT_ROOT}}"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-${HOST_PROJECT_ROOT}/workspace}"
CONTAINER_WORKSPACE="/workspace"

XHOST_GRANTED=0
revoke_x11_access() {
    if [ "${XHOST_GRANTED}" -eq 1 ]; then
        xhost -SI:localuser:"$(id -un)" >/dev/null 2>&1 || true
    fi
}
trap revoke_x11_access EXIT INT TERM

# --- 1. Build image ---
docker build \
    --file "${SCRIPT_DIR}/Dockerfile" \
    --build-arg USERNAME="$(whoami)" \
    --build-arg USER_UID="$(id -u)" \
    --build-arg USER_GID="$(id -g)" \
    --tag "${IMAGE_FULLNAME}" \
    "${SCRIPT_DIR}"

# If the first argument is --build-only, exit after building.
if [ "${1:-}" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# --- 2. Allow X11 display connection ---
if command -v xhost >/dev/null 2>&1; then
    xhost +SI:localuser:"$(id -un)" >/dev/null
    XHOST_GRANTED=1
fi

# --- 3. Build docker run options (common) ---
DOCKER_RUN_OPTS=(
    --rm
    --shm-size="2g"
    --net="host"
    --user="$(id -u):$(id -g)"
    --env="QT_X11_NO_MITSHM=1"
    --env="DISPLAY=${DISPLAY}"
    --env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
    --env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
    --env="PULSE_SERVER=${PULSE_SERVER}"
    --mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}"
    --workdir="${CONTAINER_WORKSPACE}"
    --name="${CONTAINER_NAME}"
)

# --- 4. Conditional options ---

# Attach a console only when one exists. The container never reads stdin, so a
# headless launch (an agent, nohup, CI) must not ask Docker for a TTY.
if [ -t 0 ]; then
    DOCKER_RUN_OPTS+=(--interactive --tty)
fi

# Linux-specific options (group inheritance, GPU passthrough)
if [ "${HOST_OS_TYPE}" = "Linux" ]; then
    # Inherit host group memberships
    for i in $(id -G); do
        DOCKER_RUN_OPTS+=(--group-add="${i}")
    done

    # Auto-detect GPU
    if command -v nvidia-smi >/dev/null 2>&1 || lspci 2>/dev/null | grep -qi "nvidia"; then
        # NVIDIA GPU
        DOCKER_RUN_OPTS+=(
            --gpus="all"
            --env="NVIDIA_VISIBLE_DEVICES=all"
            --env="NVIDIA_DRIVER_CAPABILITIES=all"
            --env="__GLX_VENDOR_LIBRARY_NAME=nvidia"
        )
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        # AMD GPU
        RENDER_GID=$(stat -c "%g" /dev/kfd 2>/dev/null || echo "video")
        DOCKER_RUN_OPTS+=(
            --device="/dev/kfd"
            --device="/dev/dri"
            --group-add="video"
            --group-add="${RENDER_GID}"
            --env="HSA_OVERRIDE_GFX_VERSION=11.5.1"
        )
    fi
fi

# Share /tmp with host (for X11 socket and MCP screenshot exchange)
DOCKER_RUN_OPTS+=(
    --mount="type=bind,src=/tmp,dst=/tmp"
)
if [ -e "/run/dbus/system_bus_socket" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/run/dbus/system_bus_socket,dst=/run/dbus/system_bus_socket"
    )
fi
if [ -e "${HOME}/.Xauthority" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=${HOME}/.Xauthority,dst=${HOME}/.Xauthority"
    )
fi
if [ -e "${XDG_RUNTIME_DIR}/pulse" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=${XDG_RUNTIME_DIR}/pulse,dst=${XDG_RUNTIME_DIR}/pulse"
    )
fi
# mDNS (.local) resolution via host avahi-daemon socket
if [ -e "/var/run/avahi-daemon/socket" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/var/run/avahi-daemon/socket,dst=/var/run/avahi-daemon/socket"
    )
fi

# --- 5. Run container ---
docker run "${DOCKER_RUN_OPTS[@]}" "${IMAGE_FULLNAME}"
