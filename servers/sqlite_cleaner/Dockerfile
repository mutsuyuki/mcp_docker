FROM python:3.12-slim

WORKDIR /app

# Install Docker CLI for container management
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install MCP dependencies
RUN pip install --no-cache-dir mcp>=1.4.0

# Copy the cleaner script
COPY servers/sqlite_cleaner/cleaner.py .

# Set executable permission
RUN chmod +x cleaner.py

# Run the cleaner using FastMCP
CMD ["python", "cleaner.py"]
