# Figma MCP Tips

## 接続方式

- リモートHTTP接続（`.mcp.json` に `type: "http"` + `url` で設定）
- 初回は OAuth 認証が必要。`mcp__figma__authenticate` ツールで URL を取得しブラウザで認証する
- `.mcp.json` では `"type": "http"` を省略するとスキーマエラーで全MCPサーバーが接続不能になる
- Codex は `codex mcp login figma` で認証する（`sync_mcp_config.sh` が `.codex/config.toml` に `url` を生成済み）。agy は初回接続時に OAuth（動的クライアント登録）が走る

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

### 子フレームのデフォルト高さに注意

auto-layout 内にフレームを作ると `counterAxisSizingMode` がデフォルトで `"FIXED"` になり、意図しない高さ（100px等）になることがある。テキスト内容に合わせたい場合は `"AUTO"` を明示する。

```javascript
// NG: row が 100px 固定になりコンテンツを見切る
const row = figma.createFrame();
row.layoutMode = "HORIZONTAL";
parent.appendChild(row);

// OK: 中身に合わせて縮む
row.counterAxisSizingMode = "AUTO";
```

### SPACE_BETWEEN で上下に配置

タイトルを上端、ボタンを下端に固定したい場合は `primaryAxisAlignItems = "SPACE_BETWEEN"` を使い、中央のコンテンツを別フレームにまとめる。

```javascript
frame.layoutMode = "VERTICAL";
frame.primaryAxisAlignItems = "SPACE_BETWEEN";
// → children[0] が上端、children[1] が中央、children[2] が下端に配置される
```

## デバッグ

- `use_figma` のコード内で `return` すると値を確認できる
- ノードの `id` を取得して `get_screenshot` に渡せばスクリーンショットで結果確認可能
