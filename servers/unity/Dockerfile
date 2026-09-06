FROM ubuntu:24.04

# The Unity MCP relay binary is bind-mounted from the host at runtime; this image
# only has to be able to execute it.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*
