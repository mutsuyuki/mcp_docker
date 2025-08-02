# Gemini 基本情報

## 言葉の定義

### ワークスペース

このプロジェクトにおいて、「ワークスペース」「ワークディレクトリ」または "workspace" という言葉は、特に断りがない限り、絶対パス `${HOME}/share/workspace` を指します。

#### 具体例

-   **指示**: 「ワークスペースにスクリーンショットを保存して。」
-   **解釈**: 「`${HOME}/share/workspace` にスクリーンショットを保存して。」

-   **指示**: 「`test.txt` をワークスペースに作成して。」
-   **解釈**: 「`${HOME}/share/workspace/test.txt` を作成して。」

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
```
