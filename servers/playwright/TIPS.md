# Playwright MCP Tips

## --no-sandbox は自動付与される

ブラウザ操作には `@playwright/mcp` を使用しています。
`--no-sandbox` は `servers/playwright/run.sh` が付けるため、追加設定は不要です。
