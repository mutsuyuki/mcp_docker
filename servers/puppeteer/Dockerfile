FROM mcp/puppeteer

# Install Chrome browser for GUI mode
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt update && \
    apt install -y ./google-chrome-stable_current_amd64.deb && \
    rm google-chrome-stable_current_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install additional dependencies for GUI
RUN apt update && \
    apt install -y \
        xvfb \
        x11vnc \
        fluxbox \
        wmctrl \
        libxss1 \
        libgconf-2-4 \
        libxrandr2 \
        libasound2 \
        libpangocairo-1.0-0 \
        libatk1.0-0 \
        libcairo-gobject2 \
        libgtk-3-0 \
        libgdk-pixbuf2.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["node", "/project/dist/index.js"]