FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Time zone
ARG TIMEZONE="Asia/Tokyo"
RUN echo "timezone=${TIMEZONE}"
ENV TZ=$TIMEZONE
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
RUN echo $TZ > /etc/timezone


# Prepare apt
RUN apt-get update && \
    apt-get install -y apt-file && \
    apt-file update


# Set user name from argument
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000
RUN echo "user=${USERNAME}"

# Enable sudo and create user
RUN apt-get update && \
    apt-get install -y sudo && \
    userdel -rf $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true && \
    groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -G sudo,video,audio -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# Set env for user
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/$USERNAME


# Install Build tools
RUN sudo apt-get update && \
    sudo apt-get install -y \
      build-essential \
      software-properties-common 

# Install Basic tools
RUN sudo apt-get update && \
    sudo apt-get install -y \
      git \
      wget \
      curl \
      vim \
      tmux \
      x11-apps \
      rsync \
      tree


# Japanese environment 
ENV LANGUAGE=ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends locales && \
    sudo apt-get install -y --no-install-recommends fonts-ipafont fonts-noto-cjk && \
    sudo locale-gen ja_JP.UTF-8


# Install python
ARG PYTHON_VERSION="3.12"
RUN sudo apt-get update && \
    sudo apt-get install -y \
      python${PYTHON_VERSION} \
      python${PYTHON_VERSION}-dev \
      python${PYTHON_VERSION}-venv \
      python3-pip
RUN sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    sudo update-alternatives --set python3 /usr/bin/python${PYTHON_VERSION}

# Install Built-in GUI
RUN sudo apt-get update && \
    sudo apt-get install -y libgtk-3-dev python3-tk

# Create venv
RUN sudo mkdir -p /opt/venv && sudo chown -R ${USERNAME}:${USERNAME} /opt/venv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"


# Install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - && \
    sudo apt-get update && sudo apt-get install -y nodejs