# Figma MCP Tips

## 接続方式

- リモートHTTP接続（`.mcp.json` に `type: "http"` + `url` で設定）
- 初回は OAuth 認証が必要。`mcp__figma__authenticate` ツールで URL を取得しブラウザで認証する
- `.mcp.json` では `"type": "http"` を省略するとスキーマエラーで全MCPサーバーが接続不能になる

## use_figma（Plugin API）のハマりどころ

### 操作順序が重要

`layoutSizingHorizontal = "FILL"` や `layoutSizingVertical = "FILL"` は、auto-layout の親に `appendChild` した後でないとエラーになる。

```javascript
// NG
child.layoutSizingHorizontal = "FILL";
parent.appendChild(child);

// OK
parent.appendChild(child);
child.layoutSizingHorizontal = "FILL";
```

### auto-layout フレームはテキストに縮む

`layoutMode` を設定したフレームは、デフォルトで中身のサイズに縮小される。`resize()` で指定した高さが保持されない。固定サイズにしたい場合は `primaryAxisSizingMode = "FIXED"` を明示する。

```javascript
const btn = figma.createFrame();
btn.layoutMode = "VERTICAL";
btn.primaryAxisSizingMode = "FIXED"; // これがないと高さがテキストに縮む
btn.resize(64, 64);
```

### フォント読み込みは最初に

テキストを作成する前に `await figma.loadFontAsync()` を呼ぶ。呼ばないとテキスト操作でエラーになる。Inter の場合、Semi Bold のスタイル名は `"Semi Bold"`（スペースあり）。

## デバッグ

- `use_figma` のコード内で `return` すると値を確認できる
- ノードの `id` を取得して `get_screenshot` に渡せばスクリーンショットで結果確認可能
