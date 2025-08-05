FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        freerdp2-x11 pulseaudio ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 既存 UID/GID=1000
USER 1000:1000
WORKDIR /home/ubuntu   # ubuntu ユーザーの HOME

ENV RDP_SERVER="127.0.0.1:3389" \
    RDP_USER="Docker" \
    RDP_PASS="admin"

ENTRYPOINT sh -c "xfreerdp /v:${RDP_SERVER} /u:${RDP_USER} /p:${RDP_PASS} /dynamic-resolution +clipboard /cert:ignore"