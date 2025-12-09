# Dockerfile.excel
FROM python:3.11-slim

# 依存ライブラリ
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
 && rm -rf /var/lib/apt/lists/*

# 日本語環境
RUN sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

# Excel MCP サーバー本体
RUN pip install --no-cache-dir excel-mcp-server


# ログファイルを事前に作って誰でも書き込めるようにする(rootユーザー以外でも動かせるように)
RUN python - << 'EOF'
import os
import excel_mcp.server as s
log_file = s.LOG_FILE
os.makedirs(os.path.dirname(log_file), exist_ok=True)
open(log_file, 'a').close()
os.chmod(log_file, 0o666)
print("Created world-writable log file at", log_file)
EOF

# stdio で MCP と話すモード
CMD ["excel-mcp-server", "stdio"]