#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_PROJECT_ROOT="${MCP_HOST_PROJECT_ROOT:-${PROJECT_ROOT}}"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-${HOST_PROJECT_ROOT}/workspace}"
CONTAINER_WORKSPACE="/workspace"
MODEL_ROOT="${SCRIPT_DIR}/model"
if [ -n "${MCP_HOST_PROJECT_ROOT:-}" ]; then
    HOST_MODEL_ROOT="${MCP_HOST_RAG_MODEL:-${HOST_PROJECT_ROOT}/servers/rag/model}"
else
    # Compatibility with client containers started before MCP_HOST_PROJECT_ROOT existed.
    HOST_MODEL_ROOT="${MCP_HOST_RAG_MODEL:-$(dirname -- "${HOST_WORKSPACE}")/servers/rag/model}"
fi
MODEL_NAME="Qwen3-Embedding-0.6B"
MODEL_DIR="${MODEL_ROOT}/${MODEL_NAME}"
MODEL_MARKER="${MODEL_DIR}/.model-complete"

# build
docker build \
--file "${SCRIPT_DIR}/Dockerfile" \
--tag "${IMAGE_FULLNAME}" \
"${SCRIPT_DIR}"

if [ "${1:-}" = "--build-only" ]; then
    echo "Build finished. Exiting without running the container."
    exit 0
fi

# Download lazily: building the stack does not fetch the roughly 1.2 GB model.
if [ ! -f "${MODEL_MARKER}" ]; then
    if [ "${RAG_MODEL_DOWNLOAD:-1}" = "0" ]; then
        echo "Error: RAG model is missing and RAG_MODEL_DOWNLOAD=0." >&2
        exit 1
    fi

    mkdir -p "${MODEL_ROOT}"
    exec 9>"${MODEL_ROOT}/.download.lock"
    flock 9
    if [ ! -f "${MODEL_MARKER}" ]; then
        echo "Downloading ${MODEL_NAME} (first RAG startup only)..." >&2
        docker run --rm \
            --user="$(id -u):$(id -g)" \
            --env="HF_HOME=/models/.cache" \
            --mount="type=bind,src=${HOST_MODEL_ROOT},dst=/models" \
            "${IMAGE_FULLNAME}" \
            python /app/download_model.py
    fi
fi

# Prepare RAG database directory
mkdir -p "${HOST_WORKSPACE}/rag_db"

# run
docker run \
--rm \
--interactive \
--user="$(id -u):$(id -g)" \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--mount="type=bind,src=${HOST_MODEL_ROOT},dst=/models,readonly" \
--workdir="${CONTAINER_WORKSPACE}" \
--name="${CONTAINER_NAME}" \
"${IMAGE_FULLNAME}"
