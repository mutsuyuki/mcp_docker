FROM node:22-bookworm-slim

# Install @playwright/mcp globally
RUN npm install -g @playwright/mcp@0.0.79

# Install system dependencies and browser to a shared location
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN npx -y playwright-core install-deps chromium && \
    npx -y playwright-core install --no-shell chromium && \
    chmod -R 777 ${PLAYWRIGHT_BROWSERS_PATH} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY config.json /etc/playwright-mcp/config.json

ENTRYPOINT ["playwright-mcp"]
