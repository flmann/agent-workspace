# agent-workspace

One Docker image for AI coding agents (Claude Code, Codex, OpenCode, OMP). The current directory is mounted as `/workspace`, and you work as user `agent`.

## Setup
```bash
cp .env.sample .env          # adjust AGENT_HOME, uid/gid, API keys
mkdir -p $PWD/home
chmod +x agent-workspace
# optional :
ln -s "$PWD/agent-workspace" ~/.local/bin/agent-workspace
```

## Usage
```bash
agent-workspace claude           # or codex, opencode, omp
agent-workspace                  # plain bash
agent-workspace --build claude   # rebuild the image first
```
The docker image is built on first use. Agents can be left out of the image by setting `INSTALL_CLAUDE`, `INSTALL_CODEX`, `INSTALL_OPENCODE` or `INSTALL_OMP` to `false` in `.env`; rebuild with `--build` afterwards. `AGENT_HOME` (default `~/Docker/agent-workspace/home`) is mounted as `/home/agent` and keeps logins, sessions and config.

## Included Tools
python (uv), uv, ruff, node LTS, bun, tectonic, pandoc, ffmpeg, imagemagick, poppler, git, gh, glab, ripgrep, fd, jq, yq, and standard build and debug tools.

The container is read-only, runs without capabilities, and has memory, CPU and pid limits. See `docker-compose.yml`.
