FROM mcp_base:latest

# Install LLM agents. USERNAME is a build argument from the base image and is
# not inherited by this Dockerfile, so use the persisted HOME value here.
ENV PATH="${HOME}/.local/bin:${PATH}"
RUN echo 20260706
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-package-x86_64-unknown-linux-musl.tar.gz | tar -xzf - -C "${HOME}/.local"
