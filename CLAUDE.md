# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based MCP (Model Context Protocol) server infrastructure. It provides containerized MCP servers for AI coding assistants (Claude Code, Gemini CLI, OpenAI Codex) to interact with external tools like Blender, filesystems, databases, browsers, and office documents.

## Architecture

### Layer structure

1. **Base image** (`base/Dockerfile`) - Ubuntu 24.04 + CUDA, Python 3.12, Node 22, Docker CLI, Japanese locale
2. **MCP servers** (`servers/<name>/`) - Each server is a standalone Docker container built on `mcp_base:latest`. Each has its own `Dockerfile` and `run.sh`.
3. **Client image** (`clients/Dockerfile`) - Installs AI CLI tools (claude-code, gemini-cli, codex) on top of the base image
4. **Entry point** (`run.sh`) - Builds client image, starts the container with Docker socket, GPU passthrough, X11 forwarding, and mounts

### MCP servers

Each server lives in `servers/<name>/` with a `Dockerfile` and `run.sh` that follows a consistent pattern:
- Build: `bash servers/<name>/run.sh --build-only`
- Run: `bash servers/<name>/run.sh` (builds + runs the container)
- Servers: blender, fetch, filesystem, puppeteer, sqlite, sqlite_cleaner, excel, word, rag, unity

Server registration is in `.mcp.json` (shared by Claude Code and synced to Gemini's `.gemini/settings.json` by `run.sh`).

### Workspace path convention

MCP servers run inside containers where `/workspace` maps to the host's `workspace/` directory. When using MCP tools (filesystem, RAG, Blender, etc.), always use **relative paths from the workspace root** or filenames only -- never absolute paths.

## Commands

```bash
# Build everything (base image + all servers)
bash prepare.sh

# Start the development container (builds client image, reuses running container if exists)
bash run.sh

# Build a single MCP server
bash servers/<name>/run.sh --build-only

# Build and run a single MCP server
bash servers/<name>/run.sh
```

## Environment

- API keys and secrets go in `.env` at project root (required by the RAG server, loaded by `run.sh`)
- GPU support is auto-detected (NVIDIA or AMD) in `run.sh`
- The container runs with `--net=host` and `--privileged`, with Docker socket mounted for Docker-in-Docker MCP server management

## Language

The primary user communicates in Japanese. Comments in shell scripts and configuration are in Japanese.
