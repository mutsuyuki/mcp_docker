#!/bin/bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"

# base image build
docker build \
--progress=plain \
--file "${PROJECT_ROOT}/base/Dockerfile" \
--build-arg BASE_IMAGE="ubuntu:24.04" \
--build-arg TIMEZONE="Asia/Tokyo" \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag  mcp_base:latest \
"${PROJECT_ROOT}"

# build servers
for server in blender fetch filesystem playwright sqlite sqlite_cleaner excel word rag unity; do
    bash "${PROJECT_ROOT}/servers/${server}/run.sh" --build-only
done
