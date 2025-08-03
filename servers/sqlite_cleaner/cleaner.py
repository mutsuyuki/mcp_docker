#!/usr/bin/env python3
"""
SQLite Cleaner MCP Server
シンプルな空機能サーバー（終了時のクリーンアップが目的）
"""

import logging
import sys
import subprocess
import atexit
from mcp.server.fastmcp import FastMCP

# シンプルなログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [SQLite Cleaner] %(message)s',
    stream=sys.stderr
)

def cleanup_sqlite_containers():
    """SQLiteコンテナのクリーンアップ"""
    try:
        logging.info("Starting SQLite container cleanup...")
        
        # SQLiteコンテナを検索
        result = subprocess.run(
            ["docker", "ps", "-q", "--filter", "ancestor=mcp_sqlite:latest"],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0 and result.stdout.strip():
            container_ids = [cid for cid in result.stdout.strip().split('\n') if cid]
            
            if container_ids:
                logging.info(f"Found SQLite containers: {container_ids}")
                
                # 各コンテナを停止
                for container_id in container_ids:
                    try:
                        subprocess.run(
                            ["docker", "stop", "--time=5", container_id],
                            capture_output=True,
                            timeout=10
                        )
                        logging.info(f"✅ Stopped container: {container_id}")
                    except Exception as e:
                        logging.error(f"Error stopping {container_id}: {e}")
                        
                logging.info("🧹 SQLite container cleanup completed")
            else:
                logging.info("No SQLite containers found")
        else:
            logging.info("No SQLite containers running")
            
    except Exception as e:
        logging.error(f"Cleanup error: {e}")

# 空機能のMCPサーバー作成（lifespanなし）
mcp = FastMCP("sqlite_cleaner")

def main():
    """エントリーポイント"""
    # 終了時クリーンアップ登録
    atexit.register(cleanup_sqlite_containers)
    
    logging.info("SQLite Cleaner MCP Server starting...")
    
    try:
        # シンプルにFastMCPを実行
        mcp.run()
    except KeyboardInterrupt:
        logging.info("Received interrupt signal")
    except Exception as e:
        logging.error(f"Server error: {e}")
        sys.exit(1)
    finally:
        logging.info("SQLite Cleaner MCP Server stopped")

if __name__ == "__main__":
    main()