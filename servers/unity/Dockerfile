FROM ubuntu:24.04

# The Unity MCP relay binary is bind-mounted from the host at runtime; this image
# only has to be able to execute it.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# The relay finds the Unity Editor bridge through $HOME/.unity, and run.sh mounts it
# at the host's home path, so the container user needs that same name and home.
# ubuntu:24.04 already ships a user at UID 1000, so drop it first.
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000
RUN userdel -rf $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true && \
    groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}
