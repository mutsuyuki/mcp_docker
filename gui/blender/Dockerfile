FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Blender GUI に必要なパッケージ。以前は共通ベースイメージから wget などを
# 受け取っていたが、ベースを廃止したのでこのイメージ単体で揃える。
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        wget \
        xz-utils \
        git \
        netcat-openbsd \
        # X11 / GUI関連
        libxrender1 \
        libxrandr2 \
        libxss1 \
        libxtst6 \
        libxcomposite1 \
        libxdamage1 \
        libxxf86vm1 \
        libsm6 \
        libice6 \
        libasound2t64 \
        libpangocairo-1.0-0 \
        libatk1.0-0 \
        libcairo-gobject2 \
        libgtk-3-0 \
        libgdk-pixbuf2.0-0 \
        # OpenGL / Mesa
        mesa-utils \
        libgl1-mesa-dev \
        libglu1-mesa \
        libegl1-mesa-dev \
        libglx-mesa0 \
        libwayland-egl1 \
        libdecor-0-0 \
        mesa-utils-extra \
        libosmesa6 \
        libosmesa6-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 日本語表示（旧ベースイメージが持っていた分を引き継ぐ）
ENV LANGUAGE=ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales fonts-ipafont fonts-noto-cjk && \
    locale-gen ja_JP.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the Blender version required by the official MCP extension.
ARG BLENDER_VERSION="5.2.0"
ARG BLENDER_SHA256="96f6c181a30f4950607839dc84d42a354b250d8a0231b098b59b7bc69c351c48"
RUN cd /tmp && \
    wget -O blender.tar.xz "https://download.blender.org/release/Blender5.2/blender-${BLENDER_VERSION}-linux-x64.tar.xz" && \
    echo "${BLENDER_SHA256}  blender.tar.xz" | sha256sum --check - && \
    tar -xJf blender.tar.xz -C /opt && \
    mv /opt/blender-* /opt/blender && \
    ln -s /opt/blender/blender /usr/local/bin/blender && \
    rm blender.tar.xz

# The container runs as the host user, and start_blender_gui.sh resolves paths
# through `id -un`, so that account has to exist here with the same home.
# ubuntu:24.04 already ships a user at UID 1000, so drop it first.
ARG USERNAME="user"
ARG USER_UID=1000
ARG USER_GID=1000
RUN userdel -rf $(getent passwd ${USER_UID} | cut -d: -f1) 2>/dev/null || true && \
    groupdel $(getent group ${USER_GID} | cut -d: -f1) 2>/dev/null || true && \
    groupadd -g ${USER_GID} ${USERNAME} && \
    useradd -m -u ${USER_UID} -g ${USER_GID} -s /bin/bash ${USERNAME}

# Install Blender's official MCP add-on at a reproducible revision.
ARG BLENDER_MCP_REVISION="4309a39646e644261624bfcd2bca669b343b7621"
RUN git clone https://projects.blender.org/lab/blender_mcp.git /tmp/blender_mcp && \
    git -C /tmp/blender_mcp checkout --detach "${BLENDER_MCP_REVISION}" && \
    mkdir -p /home/${USERNAME}/.config/blender/5.2/scripts/addons && \
    cp -a /tmp/blender_mcp/addon/blender_mcp_addon \
        /home/${USERNAME}/.config/blender/5.2/scripts/addons/ && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config && \
    rm -rf /tmp/blender_mcp

# 起動スクリプト
COPY --chown=${USERNAME}:${USERNAME} start_blender_gui.sh /home/${USERNAME}/
COPY --chown=${USERNAME}:${USERNAME} setup_blender_mcp.py /home/${USERNAME}/
RUN chmod +x /home/${USERNAME}/start_blender_gui.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV HOME=/home/${USERNAME}
ENV USERNAME=${USERNAME}
CMD ["/bin/bash", "-c", "/home/$USERNAME/start_blender_gui.sh"]
