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

# Word MCP サーバー本体
RUN pip install --no-cache-dir office-word-mcp-server

# stdio で MCP と話すサーバーを起動
CMD ["word_mcp_server"]