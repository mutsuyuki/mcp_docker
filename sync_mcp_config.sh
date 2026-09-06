#!/bin/bash
# Regenerate the per-client MCP configs from .mcp.json, the single source of truth.
#
#   Claude Code  reads .mcp.json directly (relative paths resolve against the project root)
#   agy          .gemini/config/mcp_config.json  "mcpServers" (stdio: command/args/env/cwd, remote: serverUrl/headers)
#   codex        .codex/config.toml              [mcp_servers.*] tables inside a marked block
#
# Both generated files are user-level configs inside the client container, so every stdio
# server gets cwd pinned to the project root there and the relative paths in .mcp.json keep
# working from any directory.
#
# Usage: sync_mcp_config.sh [container-project-root]   (default: ${HOME}/share)
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "$0")" >/dev/null 2>&1 && pwd)"
CONTAINER_PROJECT_ROOT="${1:-${HOME}/share}"
SOURCE="${PROJECT_ROOT}/.mcp.json"
AGY_CONFIG="${PROJECT_ROOT}/.gemini/config/mcp_config.json"
CODEX_CONFIG="${PROJECT_ROOT}/.codex/config.toml"

# Codex forwards only HOME/PATH/USER/LANG/TERM/... to stdio servers, so whitelist what the
# server scripts read: the variables DockerRun.sh injects into the client container plus
# every name declared in .env. Claude Code and agy pass the whole environment through.
CODEX_ENV_VARS=(
    MCP_HOST_HOME MCP_HOST_PROJECT_ROOT MCP_HOST_WORKSPACE MCP_HOST_RAG_MODEL RAG_MODEL_DOWNLOAD
    DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR
)
if [ -f "${PROJECT_ROOT}/.env" ]; then
    while IFS= read -r name; do
        CODEX_ENV_VARS+=("${name}")
    done < <(grep -oE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*' "${PROJECT_ROOT}/.env" | tr -d '[:space:]' || true)
fi
# Starting a server means docker build + docker run (RAG also loads its embedding model),
# so Codex's defaults of 10 s startup / 60 s per tool call are far too short.
CODEX_STARTUP_TIMEOUT_SEC=120
CODEX_TOOL_TIMEOUT_SEC=600

CODEX_BLOCK_BEGIN="# >>> mcp-sync: generated from .mcp.json by sync_mcp_config.sh, do not edit >>>"
CODEX_BLOCK_END="# <<< mcp-sync <<<"

# --- Validate the source ---
if ! jq -e '.mcpServers | type == "object"' "${SOURCE}" >/dev/null 2>&1; then
    echo "Error: ${SOURCE} must contain a \"mcpServers\" object." >&2
    exit 1
fi
# Claude Code expands ${VAR} inside .mcp.json; agy and codex would receive it verbatim.
if grep -q '\${' "${SOURCE}"; then
    echo "warning: ${SOURCE} uses \${VAR} expansion, which only Claude Code supports." >&2
fi
jq -r '
    .mcpServers | to_entries[] | .key as $name | .value
    | if (.command // "") != "" or .type == "http" then empty
      elif .type == "sse" then "\($name): SSE transport is not supported by codex, skipped there"
      else "\($name): transport \"\(.type // "unknown")\" is not supported by agy/codex, skipped"
      end' "${SOURCE}" | sed 's/^/warning: /' >&2

# --- agy: replace the whole "mcpServers" list, keep any other keys ---
# A recursive merge would leave servers removed from .mcp.json behind.
mkdir -p "$(dirname -- "${AGY_CONFIG}")"
[ -f "${AGY_CONFIG}" ] || echo '{}' > "${AGY_CONFIG}"
tmp="$(mktemp)"
jq --slurpfile source "${SOURCE}" --arg cwd "${CONTAINER_PROJECT_ROOT}" '
    .mcpServers = ($source[0].mcpServers | to_entries | map(
        select(((.value.command // "") != "") or (.value.type | IN("http", "sse")))
        | .value |= (if (.command // "") != "" then
              {command} + (if ((.args // []) | length) > 0 then {args} else {} end)
                        + (if ((.env // {}) | length) > 0 then {env} else {} end)
                        + {cwd: $cwd}
          else
              {serverUrl: .url} + (if ((.headers // {}) | length) > 0 then {headers} else {} end)
          end)
    ) | from_entries)' "${AGY_CONFIG}" > "${tmp}"
mv "${tmp}" "${AGY_CONFIG}"

# --- codex: rewrite only the block between the markers, keep the rest of config.toml ---
codex_block() {
    echo "${CODEX_BLOCK_BEGIN}"
    echo "# Manage servers in .mcp.json and rerun sync_mcp_config.sh. Keep this block at the end"
    echo "# of the file: TOML assigns any key written after a [table] header to that table."
    echo
    jq -r --arg cwd "${CONTAINER_PROJECT_ROOT}" \
        --argjson env_vars "$(printf '%s\n' "${CODEX_ENV_VARS[@]}" | jq -R . | jq -sc 'unique')" \
        --arg startup_timeout "${CODEX_STARTUP_TIMEOUT_SEC}" \
        --arg tool_timeout "${CODEX_TOOL_TIMEOUT_SEC}" '
        def toml_key: if test("^[A-Za-z0-9_-]+$") then . else @json end;
        def toml_table: "{ " + ([to_entries[] | "\(.key | toml_key) = \(.value | @json)"] | join(", ")) + " }";
        .mcpServers | to_entries[] | .key as $name | .value
        | if (.command // "") != "" then
            [ "[mcp_servers.\($name | toml_key)]",
              "command = \(.command | @json)",
              (if ((.args // []) | length) > 0 then "args = \(.args | @json)" else empty end),
              "cwd = \($cwd | @json)",
              (if ((.env // {}) | length) > 0 then "env = \(.env | toml_table)" else empty end),
              "env_vars = \($env_vars | @json)",
              "startup_timeout_sec = \($startup_timeout)",
              "tool_timeout_sec = \($tool_timeout)" ]
          elif .type == "http" then
            [ "[mcp_servers.\($name | toml_key)]",
              "url = \(.url | @json)",
              (if ((.headers // {}) | length) > 0 then "http_headers = \(.headers | toml_table)" else empty end),
              "tool_timeout_sec = \($tool_timeout)" ]
          else
            [ "# \($name): transport \"\(.type // "unknown")\" is not supported by codex, skipped" ]
          end
        | .[], ""' "${SOURCE}"
    echo "${CODEX_BLOCK_END}"
}

mkdir -p "$(dirname -- "${CODEX_CONFIG}")"
tmp="$(mktemp)"
{
    if [ -f "${CODEX_CONFIG}" ]; then
        # Drop the previous block and trailing blank lines, keep everything else verbatim.
        awk -v begin="${CODEX_BLOCK_BEGIN}" -v end="${CODEX_BLOCK_END}" '
            $0 == begin { skipping = 1 }
            !skipping { lines[++n] = $0 }
            $0 == end { skipping = 0 }
            END {
                while (n > 0 && lines[n] == "") n--
                for (i = 1; i <= n; i++) print lines[i]
                if (n > 0) print ""
            }' "${CODEX_CONFIG}"
    fi
    codex_block
} > "${tmp}"
# Write through the existing file so its mode survives (Codex keeps config.toml at 0600).
cat "${tmp}" > "${CODEX_CONFIG}"
rm -f "${tmp}"

echo "MCP config synced from .mcp.json:"
echo "  agy   -> ${AGY_CONFIG}"
echo "  codex -> ${CODEX_CONFIG}"
