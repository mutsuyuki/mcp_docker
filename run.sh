PROJECT_NAME=gemini
IMAGE_FULLNAME="mcp_${PROJECT_NAME}:latest"
CONTAINER_NAME="mcp_${PROJECT_NAME}_$(date "+%Y_%m%d_%H%M%S")"

# reuse running container if available 
EXISTING_CONTAINER=$(docker ps --format "{{.Image}} {{.Names}}" | grep "^${IMAGE_FULLNAME} " | awk '{print $2}' | head -n 1)
if [ -n "${EXISTING_CONTAINER}" ]; then
    echo "--- Found running container [${EXISTING_CONTAINER}].  ---"
    xhost +
    docker exec -it "${EXISTING_CONTAINER}" bash
    exit 0
fi

bash prepare.sh

# mcp client image build 
docker build \
--progress=plain \
--file gemini/Dockerfile \
--build-arg USERNAME="$(whoami)" \
--tag  ${IMAGE_FULLNAME} \
.

# create llm-agent setting folder
mkdir -p $(pwd)/.gemini

# allow display connection
xhost +

# run container 
docker run \
--interactive \
--tty \
--rm \
\
--privileged \
--gpus="all" \
--shm-size="2g" \
--net="host" \
\
$(for i in $(id -G); do echo -n --group-add="${i} "; done) \
\
--env="QT_X11_NO_MITSHM=1" \
--env="DISPLAY=${DISPLAY}" \
--env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
--env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
--env="PULSE_SERVER=${PULSE_SERVER}" \
--env="NVIDIA_DRIVER_CAPABILITIES=all" \
--env="MCP_HOST_WORKSPACE=$(pwd)/workspace" \
--env="MCP_CONTAINER_WORKSPACE=${HOME}/share/workspace" \
\
--mount="type=bind,src=$(pwd),dst=${HOME}/share" \
--mount="type=bind,src=$(pwd)/.gemini,dst=${HOME}/.gemini" \
--mount="type=bind,src=/etc/group,dst=/etc/group,readonly" \
--mount="type=bind,src=/etc/passwd,dst=/etc/passwd,readonly" \
--mount="type=bind,src=/etc/shadow,dst=/etc/shadow,readonly" \
--mount="type=bind,src=/etc/sudoers.d,dst=/etc/sudoers.d,readonly" \
--mount="type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly" \
--mount="type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock" \
\
--workdir="${HOME}/share" \
\
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME} \
\
sh -c " 
echo ------- run --------- ; 
echo Logged in at $(pwd)
bash
"
