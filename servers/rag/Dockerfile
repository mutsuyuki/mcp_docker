FROM python:3.12-slim

# ビルドツールのインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# 必要なPythonライブラリのインストール
RUN pip install --no-cache-dir \
    mcp \
    langchain-google-genai \
    langchain-chroma \
    langchain-community \
    chromadb \
    pypdf \
    python-docx \
    openpyxl \
    unstructured \
    google-generativeai

# サーバーコードを配置
COPY server.py /app/server.py
WORKDIR /app

# エントリーポイント
CMD ["python", "/app/server.py"]