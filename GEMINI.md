# Gemini 基本情報

## 言葉の定義

### ワークスペース

このプロジェクトにおいて、「ワークスペース」は各ツールの実行起点となるディレクトリを指します。

> **ℹ️ 設計メモ（人間向けの補足）**
> このシステムでは、Gemini本体とMCPサーバーで「見えている世界（カレントディレクトリ）」が異なります。
> * **Gemini (Client) の視点**: プロジェクトルート (`${HOME}/share`) にいます。
> * **MCP Server の視点**: コンテナ内の `/workspace` (ホストの `workspace` フォルダ) に閉じ込められています。
> 
> この「パスの視点のズレ」を吸収し、双方で正しくファイルを指し示すため、以下のルールによって**共通言語である「ファイル名（相対パス）」**を使用します。

**重要なルール:**
MCPツール（RAG, FileSystem, Blenderなど）を使用してファイルにアクセスする際は、**必ずファイル名のみ、またはワークスペースルートからの相対パスを使用してください。**
絶対パス（例: `/home/user/...` や `/app/...`）は使用しないでください。

#### 具体例

-   **指示**: 「ワークスペースにスクリーンショットを保存して。」
-   **解釈**: ファイル名を `screenshot.png` として保存ツールを呼び出す（絶対パスは使わない）。

-   **指示**: 「`test.txt` をワークスペースに作成して。」
-   **解釈**: ファイルパスを `test.txt` として作成ツールを呼び出す。

## Puppeteer利用時の注意点

Puppeteer を利用してブラウザを起動する際に、デフォルトの設定でエラーが発生します。
これをさけるため、以下の様に `allowDangerous` を `True` に設定し、`launchOptions` に `"--no-sandbox"` と `"--disable-setuid-sandbox"` を追加して実行してください。
また、ウィンドウサイズとコンテンツサイズを合わせるため、"defaultViewport": None の設定を追加して実行してください。

```python
print(default_api.puppeteer_navigate(
    url="<URL>",
    allowDangerous=True,
    launchOptions={
        "args": [
            "--no-sandbox",
            "--disable-setuid-sandbox"
        ],
        "defaultViewport": None
    }
))