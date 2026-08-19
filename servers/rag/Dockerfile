FROM python:3.12-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Use the CPU-only PyTorch wheel so this image does not pull CUDA libraries.
RUN pip install --no-cache-dir \
      --index-url https://download.pytorch.org/whl/cpu \
      "torch==2.6.0+cpu" && \
    pip install --no-cache-dir \
      "mcp==2.0.0" \
      "sentence-transformers==6.0.0" \
      "huggingface-hub==1.28.0" \
      "langchain-chroma==1.1.0" \
      "langchain-text-splitters==1.1.2" \
      "pypdf==6.16.1" \
      "python-docx==1.2.0" \
      "openpyxl==3.1.5" \
      "xlrd==2.0.2"

COPY server.py download_model.py /app/
WORKDIR /app

CMD ["python", "/app/server.py"]
