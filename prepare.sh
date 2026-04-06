# base image build 
docker build \
--progress=plain \
--file base/Dockerfile \
--build-arg BASE_IMAGE="nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04" \
--build-arg TIMEZONE="Asia/Tokyo" \
--build-arg USERNAME="$(whoami)" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)" \
--tag  mcp_base:latest \
.

# build servers
bash servers/blender/run.sh --build-only
bash servers/fetch/run.sh --build-only
bash servers/filesystem/run.sh --build-only
bash servers/puppeteer/run.sh --build-only
bash servers/sqlite/run.sh --build-only 
bash servers/sqlite_cleaner/run.sh --build-only
bash servers/excel/run.sh --build-only
bash servers/word/run.sh --build-only
bash servers/rag/run.sh --build-only