FROM python:3.12-slim

# Set user name from argument
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000

# Install sudo and basic tools
RUN apt-get update && \
    apt-get install -y \
      sudo \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and set permissions
RUN userdel -rf $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true && \
    groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -G sudo -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Switch to user
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/$USERNAME
ENV PATH="/home/${USERNAME}/.local/bin:$PATH"

# Install Blender's official MCP server at a reproducible revision.
ARG BLENDER_MCP_REVISION="4309a39646e644261624bfcd2bca669b343b7621"
RUN python -m pip install --user --no-cache-dir \
    "mcp[cli]==1.29.0" \
    "git+https://projects.blender.org/lab/blender_mcp.git@${BLENDER_MCP_REVISION}#subdirectory=mcp"

ENV USERNAME=${USERNAME}
WORKDIR /home/${USERNAME}

# Run blender-mcp server
CMD ["blender-mcp"]
