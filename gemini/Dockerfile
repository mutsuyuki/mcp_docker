FROM mcp_base:latest

# Set user name from argument
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000

# Install sudo
RUN apt-get update && \
    apt-get install -y \
      sudo

# Create user and set permissions
RUN userdel -rf $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true && \
    groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -G sudo,video,audio -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /opt/venv

# Switch to user
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/$USERNAME

# Install llm-agents
RUN GEMINI_VERSION=0.1.18
RUN sudo npm install -g @google/gemini-cli@${GEMINI_VERSION}
