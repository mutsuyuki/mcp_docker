FROM mcp_base:latest

# Blender GUI に必要な追加パッケージ
RUN sudo apt-get update && \
    sudo apt-get install -y \
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

# Blender 4.3.2 インストール
RUN cd /tmp && \
    wget -O blender.tar.xz "https://download.blender.org/release/Blender4.3/blender-4.3.2-linux-x64.tar.xz" && \
    sudo tar -xJf blender.tar.xz -C /opt && \
    sudo mv /opt/blender-* /opt/blender && \
    sudo ln -s /opt/blender/blender /usr/local/bin/blender && \
    rm blender.tar.xz

ARG USERNAME="user"

# Blender MCP アドオンのセットアップ
RUN mkdir -p /home/${USERNAME}/.config/blender/4.3/scripts/addons/blender_mcp && \
    cd /home/${USERNAME}/.config/blender/4.3/scripts/addons/blender_mcp && \
    (wget -O __init__.py https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py || \
     curl -L -o __init__.py https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py)

# 起動スクリプト
COPY --chown=${USERNAME}:${USERNAME} start_blender_gui.sh /home/${USERNAME}/
COPY --chown=${USERNAME}:${USERNAME} setup_blender_mcp.py /home/${USERNAME}/
RUN chmod +x /home/${USERNAME}/start_blender_gui.sh

ENV USERNAME=${USERNAME}
CMD ["/bin/bash", "-c", "/home/$USERNAME/start_blender_gui.sh"]
