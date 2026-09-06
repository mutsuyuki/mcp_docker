# AGENTS.md

Project instructions for the AI coding agents used here. Each agent looks for a
different filename, so this file is the only real one and `CLAUDE.md` and
`GEMINI.md` are symlinks to it: Claude Code reads `CLAUDE.md`, Codex reads
`AGENTS.md`, and Antigravity CLI (`agy`) reads either `AGENTS.md` or `GEMINI.md`
(the second is kept as a cheap hedge, since only its global counterpart
`~/.gemini/GEMINI.md` is documented). Edit this file; never replace a symlink
with a copy.

## Project Overview

This is a Docker-based MCP (Model Context Protocol) server infrastructure. It provides MCP servers for AI coding assistants (Claude Code, Antigravity CLI, OpenAI Codex) to interact with applications and services that need a persistent integration layer.

## Architecture

### Layer structure

1. **Client image** (`Dockerfile`) - Ubuntu 24.04, Python 3.12, Node 22, Japanese locale, and the AI CLI tools (`claude`, `agy`, `codex`). This is where you work.
2. **MCP servers** (`servers/<name>/`) - Each server is a standalone Docker container with its own `Dockerfile` and `run.sh`, built from a purpose-built upstream Python, Node, or Ubuntu image.
3. **Entry point** (`DockerRun.sh`) - Builds the client image and every server image, syncs the MCP configs, then starts the container with the Docker socket, GPU passthrough, X11 forwarding, and mounts.

### Relationship to the non-MCP template

`Dockerfile` and `DockerRun.sh` are shared with the plain (non-MCP) dev-container template and must stay byte-identical to it outside the MCP additions:
- `Dockerfile` - everything above `# change below for each project` is verbatim from the template. The MCP part is the `# --- MCP: Docker CLI ---` block inside the project-specific root section.
- `DockerRun.sh` - four blocks marked `# --- MCP: ... ---` (config sync in the reuse branch, server image builds, config sync in host prep, and three entries in `DOCKER_RUN_OPTS`).

Adding MCP to a project started from the plain template therefore means: copy `servers/`, `gui/`, `.mcp.json`, and `sync_mcp_config.sh`, paste those marked blocks, and add the MCP lines to `.gitignore`. Never rewrite the shared lines - a fix to them belongs in both templates.

### MCP servers

Each server lives in `servers/<name>/` with a `Dockerfile` and `run.sh` that follows a consistent pattern:
- Build: `bash servers/<name>/run.sh --build-only`
- Run: `bash servers/<name>/run.sh` (builds + runs the container)
- Servers: blender, playwright, rag, unity
- `run.sh` stdout is the MCP stdio channel: send build/download output to stderr (`>&2`). Claude Code and Codex skip non-JSON lines, but agy drops the server on the first one.
- Remote server: Figma (`https://mcp.figma.com/mcp`)

Server registration lives in `.mcp.json`, the single source of truth. Claude Code reads it directly; `sync_mcp_config.sh` (run by `DockerRun.sh` on every start, or by hand) regenerates the other clients' configs from it:
- `agy` -> `.gemini/config/mcp_config.json` (`mcpServers`, remote servers as `serverUrl`)
- `codex` -> the marked `[mcp_servers.*]` block at the end of `.codex/config.toml`

Edit `.mcp.json` only, never the generated files, and keep its values literal: `${VAR}` expansion is a Claude Code-only feature.

### Workspace path convention

The agent and the MCP servers see different filesystems:
- **Agent** (client container): the project root, `~/share`.
- **MCP server**: `/workspace` inside its own container, which is the host's `workspace/` directory.

To bridge the two views, address files by **filename, or a path relative to the workspace root**, whenever you call an MCP tool (RAG, Blender, Playwright, ...). Never pass an absolute path such as `/home/user/...` or `/app/...`.

- "Save a screenshot to the workspace" -> call the tool with `screenshot.png`.
- "Create test.txt in the workspace" -> call the tool with `test.txt`.

## Commands

```bash
# Build everything (client image + all server images) and start the development
# container; reuses the running container if there is one
bash DockerRun.sh

# Build a single MCP server
bash servers/<name>/run.sh --build-only

# Build and run a single MCP server
bash servers/<name>/run.sh

# Regenerate the agy / codex MCP configs after editing .mcp.json
# (DockerRun.sh does this too)
bash sync_mcp_config.sh
```

## Environment

- API keys and secrets go in `.env` at project root.
- RAG uses the local CPU model `Qwen/Qwen3-Embedding-0.6B`. Its pinned snapshot is downloaded to `servers/rag/model/` on first RAG startup, not during the image build.
- `PROJECT_ROOT` is the path visible inside the client container. `MCP_HOST_PROJECT_ROOT` is the same repository's path as seen by the Docker host and must be used for bind-mount sources. Server scripts derive the host workspace from it; `MCP_HOST_WORKSPACE` remains available as an override.
- GPU support is auto-detected (NVIDIA or AMD) in `DockerRun.sh`
- The container runs with `--net=host` and mounts the Docker socket for MCP server management. Host group memberships are forwarded so the unprivileged container user can access required devices and the Docker socket.
- Codex forwards only a fixed allowlist of environment variables to stdio MCP servers. `sync_mcp_config.sh` whitelists the `MCP_HOST_*` / display variables and every name declared in `.env`; when a server script starts reading a new variable, add it to `CODEX_ENV_VARS` there.
- Figma (remote HTTP) needs a one-time OAuth login per client: Claude Code via the `mcp__figma__authenticate` tool, Codex via `codex mcp login figma`, agy on first use (dynamic client registration).

## MCP Tips

Before using an MCP server, check if `servers/<name>/TIPS.md` exists and read it for known pitfalls.

## Language

The primary user communicates in Japanese. Comments in shell scripts and configuration are in English, and so is this file; the per-server `TIPS.md` notes are in Japanese.
