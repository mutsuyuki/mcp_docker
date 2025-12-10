FROM python:3.12-slim

WORKDIR /app

# Install Docker CLI
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
RUN pip install --no-cache-dir mcp~=1.12

# Copy the cleaner script to /app/cleaner.py
COPY cleaner.py .

# Run using absolute path
CMD ["python", "/app/cleaner.py"]