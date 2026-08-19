FROM mcp_base:latest

# Blender GUI に必要な追加パッケージ
RUN sudo apt-get update && \
    sudo apt-get install -y \
        git \
        netcat-openbsd \
        # X11 / GUI関連
        libxrender1 \
        libxrandr2 \
        libxss1 \
        libxtst6 \
        libxcomposite1 \
        libasound2t64 \
        libpangocairo-1.0-0 \
        libatk1.0-0 \
        libcairo-gobject2 \
        libgtk-3-0 \
        libgdk-pixbuf2.0-0 \
        libxdamage1 \
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
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

# Install the Blender version required by the official MCP extension.
ARG BLENDER_VERSION="5.2.0"
ARG BLENDER_SHA256="96f6c181a30f4950607839dc84d42a354b250d8a0231b098b59b7bc69c351c48"
RUN cd /tmp && \
    wget -O blender.tar.xz "https://download.blender.org/release/Blender5.2/blender-${BLENDER_VERSION}-linux-x64.tar.xz" && \
    echo "${BLENDER_SHA256}  blender.tar.xz" | sha256sum --check - && \
    sudo tar -xJf blender.tar.xz -C /opt && \
    sudo mv /opt/blender-* /opt/blender && \
    sudo ln -s /opt/blender/blender /usr/local/bin/blender && \
    rm blender.tar.xz

ARG USERNAME="user"

# Install Blender's official MCP add-on at a reproducible revision.
ARG BLENDER_MCP_REVISION="4309a39646e644261624bfcd2bca669b343b7621"
RUN git clone https://projects.blender.org/lab/blender_mcp.git /tmp/blender_mcp && \
    git -C /tmp/blender_mcp checkout --detach "${BLENDER_MCP_REVISION}" && \
    mkdir -p /home/${USERNAME}/.config/blender/5.2/scripts/addons && \
    cp -a /tmp/blender_mcp/addon/blender_mcp_addon \
        /home/${USERNAME}/.config/blender/5.2/scripts/addons/ && \
    rm -rf /tmp/blender_mcp

# 起動スクリプト
COPY --chown=${USERNAME}:${USERNAME} start_blender_gui.sh /home/${USERNAME}/
COPY --chown=${USERNAME}:${USERNAME} setup_blender_mcp.py /home/${USERNAME}/
RUN chmod +x /home/${USERNAME}/start_blender_gui.sh

ENV USERNAME=${USERNAME}
CMD ["/bin/bash", "-c", "/home/$USERNAME/start_blender_gui.sh"]
