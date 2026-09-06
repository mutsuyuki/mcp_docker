#!/bin/bash

# コンテナ設定
HOST_OS_TYPE=$(uname -s)
BASE_IMAGE="ubuntu:24.04"
# スクリプトの場所を基準にする（実行ディレクトリに依存しない）
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
IMAGE_REPOSITORY="$(basename "${PROJECT_ROOT}")"
IMAGE_TAG="latest"
IMAGE_FULLNAME="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
CONTAINER_NAME="${IMAGE_REPOSITORY}_$(date "+%Y_%m%d_%H%M%S")"

# 横断ナレッジ
HOST_KNOWLEDGE_DIR="${HOME}/@sync/@docker/knowledge"


# --- 1. 既存コンテナの再利用 ---
EXISTING_CONTAINER=$(docker ps --format "{{.Image}} {{.Names}}" | grep "^${IMAGE_FULLNAME} " | awk '{print $2}' | head -n 1)
if [ -n "${EXISTING_CONTAINER}" ]; then
    echo "--- Found running container [${EXISTING_CONTAINER}].  ---"
    # --- MCP: コンテナ起動中に編集した .mcp.json を各エージェントへ反映 ---
    bash "${PROJECT_ROOT}/sync_mcp_config.sh"
    if command -v xhost >/dev/null 2>&1; then xhost +; fi
    docker exec -it "${EXISTING_CONTAINER}" bash
    exit 0
fi

# --- 2. イメージのビルド ---
docker build \
    --progress=plain \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg TIMEZONE="Asia/Tokyo" \
    --build-arg PYTHON_VERSION="3.12" \
    --build-arg NODE_VERSION="22" \
    --build-arg USERNAME="$(whoami)" \
    --build-arg USER_UID="$(id -u)" \
    --build-arg USER_GID="$(id -g)" \
    --tag "${IMAGE_FULLNAME}" \
    "${PROJECT_ROOT}"

# --- MCP: サーバーイメージのビルド ---
for server in blender playwright rag unity; do
    bash "${PROJECT_ROOT}/servers/${server}/run.sh" --build-only
done

# --- 3. ホスト側のディレクトリ・ファイル準備 ---
# 環境変数
touch "${PROJECT_ROOT}/.env"

# AWS設定
mkdir -p "${PROJECT_ROOT}/.aws"
chmod 700 "${PROJECT_ROOT}/.aws"

# Gemini設定
mkdir -p "${PROJECT_ROOT}/.gemini"

# Claude設定
mkdir -p "${PROJECT_ROOT}/.claude"
touch "${PROJECT_ROOT}/.claude.json"

# Codex設定
mkdir -p "${PROJECT_ROOT}/.codex"
CODEX_CONFIG="${PROJECT_ROOT}/.codex/config.toml"
touch "${CODEX_CONFIG}"
if ! grep -Eq '^[[:space:]]*(default_permissions|sandbox_mode)[[:space:]]*=' "${CODEX_CONFIG}"; then
    CODEX_CONFIG_TMP=$(mktemp "${CODEX_CONFIG}.tmp.XXXXXX")
    {
        printf 'default_permissions = ":danger-full-access"\n'
        cat "${CODEX_CONFIG}"
    } > "${CODEX_CONFIG_TMP}"
    mv "${CODEX_CONFIG_TMP}" "${CODEX_CONFIG}"
fi

# 横断ナレッジ
mkdir -p "${HOST_KNOWLEDGE_DIR}"

# --- MCP: .mcp.json から agy / codex の設定を生成 ---
bash "${PROJECT_ROOT}/sync_mcp_config.sh"

# X11アクセス許可
if command -v xhost >/dev/null 2>&1; then xhost +; fi

# --- 4. 実行オプションの構築（共通部分） ---
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
    --env-file="${PROJECT_ROOT}/.env"
    --mount="type=bind,src=${PROJECT_ROOT},dst=${HOME}/share"
    --mount="type=bind,src=${PROJECT_ROOT}/.aws,dst=${HOME}/.aws"
    --mount="type=bind,src=${PROJECT_ROOT}/.gemini,dst=${HOME}/.gemini"
    --mount="type=bind,src=${PROJECT_ROOT}/.claude,dst=${HOME}/.claude"
    --mount="type=bind,src=${PROJECT_ROOT}/.claude.json,dst=${HOME}/.claude.json"
    --mount="type=bind,src=${PROJECT_ROOT}/.codex,dst=${HOME}/.codex"
    --mount="type=bind,src=${HOST_KNOWLEDGE_DIR},dst=${HOME}/knowledge"
    # --- MCP: サーバーコンテナの起動と、ホスト側から見たパスの受け渡し ---
    --env="MCP_HOST_HOME=${HOME}"
    --env="MCP_HOST_PROJECT_ROOT=${PROJECT_ROOT}"
    --mount="type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock"
    --security-opt="seccomp=unconfined"
    --workdir="${HOME}/share"
    --name="${CONTAINER_NAME}"
)

# --- 5. 条件分岐によるオプションの追加 ---

# Linux固有のオプション（グループ追加、GPUパススルー）
if [ "${HOST_OS_TYPE}" = "Linux" ]; then
    # ホスト側の所属グループをコンテナにも引き継ぐ
    for i in $(id -G); do
        DOCKER_RUN_OPTS+=(--group-add="${i}")
    done

    # GPUの自動判定（lspci が無い環境もあるので nvidia-smi も見る）
    if command -v nvidia-smi >/dev/null 2>&1 || lspci 2>/dev/null | grep -qi "nvidia"; then
        # Nvidia のGPUの場合
        DOCKER_RUN_OPTS+=(
            --gpus="all" 
            --env="NVIDIA_DRIVER_CAPABILITIES=all"
        )
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        # AMD のGPUの場合
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

# 存在する場合のみマウントするファイル群（LinuxのGUI / オーディオ等）
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

# mDNS (.local) 名前解決用（ホストの avahi-daemon ソケットを共有）
if [ -e "/var/run/avahi-daemon/socket" ]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/var/run/avahi-daemon/socket,dst=/var/run/avahi-daemon/socket"
    )
fi

# ホスト側の /etc/group をコンテナにマウントする（読み取り専用）
if [[ -r /etc/group ]]; then
    DOCKER_RUN_OPTS+=(
        --mount="type=bind,src=/etc/group,dst=/etc/group,readonly"
    )
fi


# --- 6. コンテナの起動 ---
docker run "${DOCKER_RUN_OPTS[@]}" "${IMAGE_FULLNAME}" \
sh -c "
echo ------- run --------- ;
echo Logged in at \$(pwd) ;
echo Image: ${IMAGE_FULLNAME} ;

echo --- knowledge link --- ;
STUBS=\"\$HOME/knowledge/stubs\" ;
mkdir -p \"\$HOME/.claude\" \"\$HOME/.codex\" \"\$HOME/.gemini\" ;
ln -sf \"\$STUBS/CLAUDE.md\" \"\$HOME/.claude/CLAUDE.md\" ;
ln -sf \"\$STUBS/AGENTS.md\" \"\$HOME/.codex/AGENTS.md\" ;
ln -sf \"\$STUBS/GEMINI.md\" \"\$HOME/.gemini/GEMINI.md\" ;
ls \$STUBS ;

bash
"
