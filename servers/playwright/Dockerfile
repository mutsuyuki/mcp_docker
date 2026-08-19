FROM node:22-bookworm-slim

# Install @playwright/mcp globally
RUN npm install -g @playwright/mcp@0.0.79

# Install the browser revision required by this exact MCP release.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers
RUN node /usr/local/lib/node_modules/@playwright/mcp/node_modules/playwright/cli.js install-deps chromium && \
    node /usr/local/lib/node_modules/@playwright/mcp/node_modules/playwright/cli.js install chromium && \
    chmod -R 777 ${PLAYWRIGHT_BROWSERS_PATH} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY config.json /etc/playwright-mcp/config.json

ENTRYPOINT ["playwright-mcp"]
