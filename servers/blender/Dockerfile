FROM python:3.12-slim

# Set user name from argument
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000

# Install sudo and basic tools
RUN apt-get update && \
    apt-get install -y \
      sudo \
      curl && \
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

# Install uv and blender-mcp
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/${USERNAME}/.local/bin:$PATH"
RUN /home/${USERNAME}/.local/bin/uv tool install blender-mcp

ENV USERNAME=${USERNAME}
WORKDIR /home/${USERNAME}

# Run blender-mcp server
CMD ["uv", "tool", "run", "blender-mcp"]