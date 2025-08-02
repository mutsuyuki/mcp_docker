SERVER_NAME=$(basename $(dirname $0))
IMAGE_FULLNAME="mcp_${SERVER_NAME}:latest"
CONTAINER_NAME="mcp_${SERVER_NAME}_$(date "+%Y_%m%d_%H%M%S")"
HOST_WORKSPACE="${MCP_HOST_WORKSPACE:-$(pwd)/workspace}"
CONTAINER_WORKSPACE="${MCP_CONTAINER_WORKSPACE:-$(pwd)/workspace}"

# build 
docker build \
--file $(dirname $0)/Dockerfile \
--progress=plain \
--tag  ${IMAGE_FULLNAME} \
.

# allow display connection for GUI
xhost +

# run with GUI support
docker run \
--rm \
--interactive \
--shm-size="2g" \
--user="$(id -u):$(id -g)" \
--env="QT_X11_NO_MITSHM=1" \
--env="DISPLAY=${DISPLAY}" \
--env="WAYLAND_DISPLAY=${WAYLAND_DISPLAY}" \
--env="XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR}" \
--env="PULSE_SERVER=${PULSE_SERVER}" \
--mount="type=bind,src=${HOST_WORKSPACE},dst=${CONTAINER_WORKSPACE}" \
--mount="type=bind,src=/tmp/.X11-unix,dst=/tmp/.X11-unix,readonly" \
--mount="type=bind,src=/run/dbus/system_bus_socket,dst=/run/dbus/system_bus_socket" \
--name=${CONTAINER_NAME} \
${IMAGE_FULLNAME} \
${CONTAINER_WORKSPACE}