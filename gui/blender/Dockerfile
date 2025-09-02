FROM mcp_base:latest

# Install Blender dependencies for GUI
RUN sudo apt-get update && \
    sudo apt-get install -y \
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
        wget \
        netcat-openbsd \
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

# Install Blender (4.3.2)
RUN cd /tmp && \
    wget -O blender.tar.xz "https://download.blender.org/release/Blender4.3/blender-4.3.2-linux-x64.tar.xz" && \
    sudo tar -xJf blender.tar.xz -C /opt && \
    sudo mv /opt/blender-* /opt/blender && \
    sudo ln -s /opt/blender/blender /usr/local/bin/blender && \
    rm blender.tar.xz


ARG USERNAME="user"

# Create addon directory structure
RUN mkdir -p /home/${USERNAME}/.config/blender/4.3/scripts/addons/blender_mcp

# Download and setup Blender MCP addon
RUN cd /home/${USERNAME}/.config/blender/4.3/scripts/addons/blender_mcp && \
    (wget -O __init__.py https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py || \
     wget -O __init__.py https://github.com/ahujasid/blender-mcp/raw/main/addon.py || \
     curl -L -o __init__.py https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py)

# Copy startup scripts
COPY --chown=${USERNAME}:${USERNAME} start_blender_gui.sh /home/${USERNAME}/
COPY --chown=${USERNAME}:${USERNAME} setup_blender_mcp.py /home/${USERNAME}/
RUN chmod +x /home/${USERNAME}/start_blender_gui.sh

# GUI環境設定 + OpenGL互換設定
ENV DISPLAY=:0
ENV QT_X11_NO_MITSHM=1
ENV MESA_GL_VERSION_OVERRIDE=4.3
ENV MESA_GLSL_VERSION_OVERRIDE=430
ENV LIBGL_ALWAYS_SOFTWARE=1

ENV USERNAME=${USERNAME}
WORKDIR /home/${USERNAME}
CMD ["/bin/bash", "-c", "/home/$USERNAME/start_blender_gui.sh"]
