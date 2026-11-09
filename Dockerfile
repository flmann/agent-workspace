FROM node:lts-trixie-slim AS node
FROM oven/bun:1 AS bun
FROM ghcr.io/astral-sh/uv:latest AS uv

FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG TECTONIC_VERSION=0.17.0
ARG YQ_VERSION=4.54.3
ARG GLAB_VERSION=1.128.0
ARG AGENT_UID=1000
ARG AGENT_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget git openssh-client gh \
        ripgrep fd-find tree jq \
        build-essential pkg-config make \
        less diffutils patch unzip zip file \
        pandoc poppler-utils ffmpeg imagemagick \
        procps htop lsof iputils-ping dnsutils \
        fonts-lmodern \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) tectonic_arch=x86_64 ;; \
        arm64) tectonic_arch=aarch64 ;; \
        *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${arch}" \
        -o /usr/local/bin/yq; \
    chmod +x /usr/local/bin/yq; \
    curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/v${GLAB_VERSION}/downloads/glab_${GLAB_VERSION}_linux_${arch}.deb" \
        -o /tmp/glab.deb; \
    apt-get update; apt-get install -y --no-install-recommends /tmp/glab.deb; \
    rm -rf /tmp/glab.deb /var/lib/apt/lists/*; \
    curl -fsSL "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${TECTONIC_VERSION}/tectonic-${TECTONIC_VERSION}-${tectonic_arch}-unknown-linux-musl.tar.gz" \
        | tar -xz -C /usr/local/bin tectonic; \
    chmod +x /usr/local/bin/tectonic; \
    yq --version; glab --version; tectonic --version

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --from=uv /uv /uvx /usr/local/bin/

ENV BUN_INSTALL=/opt/bun \
    UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_TOOL_DIR=/opt/uv/tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    UV_PYTHON_PREFERENCE=managed \
    PATH="/opt/bun/bin:${PATH}"

RUN uv python install --default \
    && uv tool install ruff \
    && uv tool install pdf-reader-mcp \
    && chmod -R a+rX /opt/uv

RUN npm install -g \
        @anthropic-ai/claude-code \
        @openai/codex \
        opencode-ai \
    && bun install -g @oh-my-pi/pi-coding-agent @oh-my-pi/pi-natives \
    && chmod -R a+rX /opt/bun \
    && npm cache clean --force

RUN groupadd -g "${AGENT_GID}" agent \
    && useradd -m -u "${AGENT_UID}" -g agent -s /bin/bash agent

ENV HOME=/home/agent \
    TERM=xterm-256color \
    TZ=Europe/Berlin \
    PATH="/home/agent/.local/bin:${PATH}"

USER agent
WORKDIR /workspace

CMD ["bash"]
