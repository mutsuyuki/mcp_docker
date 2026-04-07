#!/bin/bash

HOST_OS_TYPE=$(uname -s)
IMAGE_REPOSITORY="mcp_clients"
IMAGE_TAG="latest"
IMAGE_FULLNAME="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
CONTAINER_NAME="${IMAGE_REPOSITORY}_$(date "+%Y_%m%d_%H%M%S")"

# --- 1. Reuse existing container ---
EXISTING_CONTAINER=$(docker ps --format "{{.Image}} {{.Names}}" | grep "^${IMAGE_FULLNAME} " | awk '{print $2}' | head -n 1)
if [ -n "${EXISTING_CONTAINER}" ]; then
    echo "--- Found running container [${EXISTING_CONTAINER}].  ---"
    if command -v xhost >/dev/null 2>&1; then xhost +; fi
    docker exec -it "${EXISTING_CONTAINER}" bash
    exit 0
fi

# --- 2. Build images ---
bash prepare.sh

docker build \
    --progress=plain \
    --file clients/Dockerfile \
    --build-arg USERNAME="$(whoami)" \
    --tag "${IMAGE_FULLNAME}" \
    .

# --- 3. Prepare host directories and files ---
touch "$(pwd)/.env"
mkdir -p "$(pwd)/.gemini"
mkdir -p "$(pwd)/.claude"
touch "$(pwd)/.claude.json"
mkdir -p "$(pwd)/.codex"

if command -v xhost >/dev/null 2>&1; then xhost +; fi

# --- 4. Sync MCP config (.mcp.json -> .gemini/settings.json) ---
if [ -f "$(pwd)/.mcp.json" ]; then
    if [ ! -f "$(pwd)/.gemini/settings.json" ]; then
        echo "{}" > "$(pwd)/.gemini/settings.json"
    fi
    # Merge mcpServers from .mcp.json into settings.json
    jq -s '.[0] * .[1]' "$(pwd)/.gemini/settings.json" "$(pwd)/.mcp.json" > "$(pwd)/.gemini/settings.tmp.json" && \
    mv "$(pwd)/.gemini/settings.tmp.json" "$(pwd)/.gemini/settings.json"
fi

# --- 5. Build docker run options (common) ---
DOCKER_RUN_OPTS=(
    --interactive
    --tty
    --rm
    --shm-size="2g"
    --net="host"
    --env="QT_X11_NO_MITSHM=1"
    --env="DISPLAY=${DISPLAY}"
    --env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}"
    --env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}"
    --env="PULSE_SERVER=${PULSE_SERVER}"
    --env="COLORTERM=truecolor"
    --env-file="$(pwd)/.env"
    --env="MCP_HOST_HOME=${HOME}"
    --env="MCP_HOST_WORKSPACE=$(pwd)/workspace"
    --mount="type=bind,src=$(pwd),dst=${HOME}/share"
    --mount="type=bind,src=$(pwd)/.gemini,dst=${HOME}/.gemini"
    --mount="type=bind,src=$(pwd)/.claude,dst=${HOME}/.claude"
    --mount="type=bind,src=$(pwd)/.claude.json,dst=${HOME}/.claude.json"
    --mount="type=bind,src=$(pwd)/.codex,dst=${HOME}/.codex"
    --mount="type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock"
    --privileged
    --workdir="${HOME}/share"
    --name="${CONTAINER_NAME}"
)

# --- 6. Conditional options ---

# Linux-specific options (group inheritance, GPU passthrough)
if [ "${HOST_OS_TYPE}" = "Linux" ]; then
    # Inherit host group memberships
    for i in $(id -G); do
        DOCKER_RUN_OPTS+=(--group-add="${i}")
    done

    # Auto-detect GPU
    if lspci 2>/dev/null | grep -qi "nvidia"; then
        # NVIDIA GPU
        DOCKER_RUN_OPTS+=(
            --gpus="all" 
            --env="NVIDIA_DRIVER_CAPABILITIES=all"
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

# Conditionally mount files (X11 / audio etc.)
if [ -e "/tmp/.X11-unix" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly"
    )
fi
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

# mDNS (.local) resolution via host avahi-daemon socket
if [ -e "/var/run/avahi-daemon/socket" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/var/run/avahi-daemon/socket,dst=/var/run/avahi-daemon/socket"
    )
fi

# --- 7. Run container ---
docker run "${DOCKER_RUN_OPTS[@]}" "${IMAGE_FULLNAME}" \
sh -c "
echo ------- run --------- ;
echo Logged in at \$(pwd) ;
echo Image: ${IMAGE_FULLNAME} ;
bash
"