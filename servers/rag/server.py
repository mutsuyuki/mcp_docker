import os
import glob
from typing import List
from mcp.server.fastmcp import FastMCP
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from langchain_community.document_loaders import (
    PyPDFLoader,
    Docx2txtLoader,
    UnstructuredExcelLoader,
    TextLoader,
    UnstructuredMarkdownLoader
)
from langchain_text_splitters import RecursiveCharacterTextSplitter

# ---------------------------------------------------------
# 設定
# ---------------------------------------------------------
# コンテナ内のカレントディレクトリ(.)を起点にする
WORKSPACE_BASE = "." 
PERSIST_DIRECTORY = os.path.join(WORKSPACE_BASE, "rag_db")

# Gemini Embeddingモデル
EMBEDDING_MODEL = "models/gemini-embedding-001"

# ---------------------------------------------------------
# MCPサーバー初期化
# ---------------------------------------------------------
mcp = FastMCP("rag_server")

def get_vectorstore():
    """ChromaDBのインスタンスを取得または作成"""
    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    
    if not api_key:
        raise ValueError("GEMINI_API_KEY or GOOGLE_API_KEY environment variable is not set.")

    # ディレクトリが存在しない場合は作成する（権限エラー回避の保険）
    if not os.path.exists(PERSIST_DIRECTORY):
        try:
            os.makedirs(PERSIST_DIRECTORY, exist_ok=True)
        except Exception as e:
            print(f"Warning: Failed to create directory {PERSIST_DIRECTORY}: {e}")

    embeddings = GoogleGenerativeAIEmbeddings(
        model=EMBEDDING_MODEL,
        google_api_key=api_key
    )

    vectorstore = Chroma(
        collection_name="medical_docs",
        embedding_function=embeddings,
        persist_directory=PERSIST_DIRECTORY,
    )
    return vectorstore

def load_file(file_path: str):
    """拡張子に応じて適切なローダーを選択"""
    ext = os.path.splitext(file_path)[1].lower()
    
    if ext == ".pdf":
        return PyPDFLoader(file_path).load()
    elif ext in [".docx", ".doc"]:
        return Docx2txtLoader(file_path).load()
    elif ext in [".xlsx", ".xls"]:
        return UnstructuredExcelLoader(file_path).load()
    elif ext == ".md":
        return UnstructuredMarkdownLoader(file_path).load()
    else:
        return TextLoader(file_path, autodetect_encoding=True).load()

# ---------------------------------------------------------
# ツール定義
# ---------------------------------------------------------

@mcp.tool()
def add_documents(file_paths: List[str]) -> str:
    """
    指定されたファイル（PDF, Word, Excel, MD等）を読み込み、
    Gemini APIでベクトル化してデータベースに追加します。
    パスはファイル名、またはワークスペースからの相対パスで指定可能です。
    """
    try:
        vectorstore = get_vectorstore()
        all_docs = []

        for path in file_paths:
            # 絶対パスが来ても、ファイル名だけ抽出してカレントディレクトリ起点として扱う
            # (GEMINI.mdで相対パスを強制しているが、安全のため)
            if os.path.isabs(path):
                full_path = os.path.basename(path)
            else:
                full_path = path

            # ワイルドカード対応
            for resolved_path in glob.glob(full_path):
                if not os.path.exists(resolved_path):
                    print(f"File not found: {resolved_path}")
                    continue
                
                try:
                    docs = load_file(resolved_path)
                    all_docs.extend(docs)
                except Exception as e:
                    return f"Error loading {resolved_path}: {str(e)}"

        if not all_docs:
            return f"No documents found or loaded. (Current directory: {os.getcwd()})"

        # テキスト分割
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            separators=["\n\n", "\n", "。", "、", " ", ""]
        )
        splits = text_splitter.split_documents(all_docs)

        # ベクトル化と保存
        vectorstore.add_documents(documents=splits)
        
        return f"Successfully added {len(splits)} chunks from {len(file_paths)} file sources to the RAG database."

    except Exception as e:
        import traceback
        return f"Error adding documents: {str(e)}\n{traceback.format_exc()}"

@mcp.tool()
def query_knowledge_base(query: str, n_results: int = 5) -> str:
    """
    蓄積されたドキュメントデータベースから、質問に関連する情報を検索します。
    """
    try:
        vectorstore = get_vectorstore()
        
        results = vectorstore.similarity_search(query, k=n_results)
        
        output = "### Search Results\n\n"
        for i, doc in enumerate(results):
            source = doc.metadata.get("source", "Unknown")
            source_name = os.path.basename(source)
            page = doc.metadata.get("page", "N/A")
            content = doc.page_content.replace("\n", " ")
            
            output += f"**Source {i+1}:** {source_name} (Page: {page})\n"
            output += f"> {content}\n\n"
            
        return output

    except Exception as e:
        return f"Error querying database: {str(e)}"

@mcp.tool()
def clear_database() -> str:
    """データベースをリセットします（全削除）。"""
    try:
        vectorstore = get_vectorstore()
        vectorstore.delete_collection()
        return "RAG database cleared successfully."
    except Exception as e:
        return f"Error clearing database: {str(e)}"

if __name__ == "__main__":
    mcp.run()