# base image build 
docker build \
--progress=plain \
--file base/Dockerfile \
--build-arg BASE_IMAGE="nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04" \
--build-arg TIMEZONE="Asia/Tokyo" \
--build-arg USERNAME="$(whoami)" \
--tag  mcp_base:latest \
.

# build servers
bash servers/blender/run.sh --build-only
bash servers/fetch/run.sh --build-only
bash servers/filesystem/run.sh --build-only
bash servers/puppeteer/run.sh --build-only
bash servers/sqlite/run.sh --build-only 
bash servers/sqlite_cleaner/run.sh --build-only
