#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
TIMESTAMP="$(date "+%Y_%m%d_%H%M%S")"

export IMAGE_FULLNAME_WIN="mcp_${PROJECT_NAME}_win11:latest"
export IMAGE_FULLNAME_RDP="mcp_${PROJECT_NAME}_rdp:latest"

export CONTAINER_NAME_WIN="mcp_${PROJECT_NAME}_win11_${TIMESTAMP}"
export CONTAINER_NAME_RDP="mcp_${PROJECT_NAME}_rdp_${TIMESTAMP}"


xhost +

docker compose up  --build
