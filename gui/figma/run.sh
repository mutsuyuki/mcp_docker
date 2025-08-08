#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
TIMESTAMP="$(date "+%Y_%m%d_%H%M%S")"

export IMAGE_FULLNAME_WIN="mcp_${PROJECT_NAME}_win11:latest"
export IMAGE_FULLNAME_RDP="mcp_${PROJECT_NAME}_rdp:latest"

export CONTAINER_NAME_WIN="mcp_${PROJECT_NAME}_win11_${TIMESTAMP}"
export CONTAINER_NAME_RDP="mcp_${PROJECT_NAME}_rdp_${TIMESTAMP}"


xhost +

WIN_IMG="${SCRIPT_DIR}/windows/data.img"
if [[ ! -f "$WIN_IMG" ]]; then
  echo "Open vnc display to monitor installation." >&2
  sensible-browser "http://127.0.0.1:8006/" >/dev/null 2>&1 &
fi

docker compose up  --build
