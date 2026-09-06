ARG BASE_IMAGE="ubuntu:24.04"
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Time zone
ARG TIMEZONE="Asia/Tokyo"
RUN echo "timezone=${TIMEZONE}"
ENV TZ=$TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

# Prepare apt
RUN apt-get update && \
    apt-get install -y apt-file && \
    apt-file update

# Install Build tools
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      software-properties-common

# Install Basic tools
RUN apt-get update && \
    apt-get install -y \
      git \
      gh \
      wget \
      curl \
      vim \
      tmux \
      x11-apps \
      rsync \
      tree \
      zip \
      unzip \
      jq \
      ripgrep \
      ffmpeg \
      libnss-mdns

# Japanese environment 
ENV LANGUAGE=ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    apt-get install -y --no-install-recommends fonts-ipafont fonts-noto-cjk && \
    locale-gen ja_JP.UTF-8

# Install python
ARG PYTHON_VERSION="3.12"
RUN apt-get update && \
    apt-get install -y \
      python${PYTHON_VERSION} \
      python${PYTHON_VERSION}-dev \
      python${PYTHON_VERSION}-venv \
      python3-pip && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --set python3 /usr/bin/python${PYTHON_VERSION}

# Install Built-in GUI
RUN apt-get update && \
    apt-get install -y libgtk-3-dev python3-tk

# Create venv (as root, but make it accessible to user later)
RUN mkdir -p /opt/venv && \
    python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install nodejs
ARG NODE_VERSION="22"
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get update && apt-get install -y nodejs
ENV NODE_PATH=/usr/lib/node_modules

# Install playwright-core
RUN npm install -g playwright-core

# Install AWS CLI
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install --update && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# Set user name from argument
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000
RUN echo "user=${USERNAME}"

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
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Change owner of venv to USER
RUN chown -R ${USERNAME}:${USERNAME} /opt/venv


# ========================================
# change below for each project
# ========================================
# --- project-specific: root ---
USER root

# RUN apt-get update && \
#     apt-get install -y \
#       package-name

# --- MCP: Docker CLI ---
# MCPサーバーはそれぞれ別コンテナで動くため、コンテナ内から docker を叩けるようにする。
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# --- project-specific: user ---
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}

RUN python3 -m pip install --no-cache-dir --upgrade pip


# Install llm-agents
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"
RUN echo 20260706
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-package-x86_64-unknown-linux-musl.tar.gz | tar -xzf - -C "${HOME}/.local"
