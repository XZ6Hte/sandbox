# CLAUDE.md

## Purpose

Containerised dev environment for agentic coding, modelled on the c't article
"Schluss mit Vibe-Coding" (Jan Mahn, 2026-10-16). The coding agent runs inside
the container; only the bind-mounted `workspace/` is visible as a host path
(selected `config/` files are mounted read-only). Image includes PHP 8.5
(+ Laravel extensions), Composer, Node 22, npm, Bun, git, `gh`, ripgrep, jq,
sqlite3, OpenCode 2 and Claude Code, plus two skills: `/plan-item` and
`/implement-item`.

This repo is the sandbox tooling itself (no application code). Real projects
live in `workspace/`.

## Structure

- `Dockerfile`, `compose.yaml` - image recipe; mounts, env, volumes
- `sandbox.sh` / `sandbox.ps1` - preflight checks + shell (Windows: ps1)
- `.env.example` -> `.env` (git-ignored, mode 600)
- `scripts/entrypoint.sh` - git identity, safe.directory, gh credential helper
- `scripts/install-docker-wsl.sh` - installs Docker Engine in WSL 2
- `config/skills/{plan-item,implement-item}/SKILL.md` (+ `references/`) - single
  source of truth for workflows, mounted for both agents
- `config/commands/{plan-item,implement-item}.md` - OpenCode slash-command
  wrappers that load the skills
- `config/memory/AGENTS.md` - sandbox-wide rules, mounted read-only as
  OpenCode's AGENTS.md and Claude's `~/.claude/CLAUDE.md`
- `config/claude/settings.json`, `config/opencode/opencode.jsonc` - agent config
- `TODO.md` - backlog, mounted read-only as `/home/dev/TODO.md`; agents read it
  at session start
- `workspace/` - user projects (bind mount; only writable host path)
- Docs: `README.md` (operational reference), `HANDOVER.md`, `TODO.md`

## Commands

```sh
./sandbox.sh                 # build if needed, start, open a shell (default: run)
./sandbox.sh exec <cmd...>   # run one command inside
./sandbox.sh build           # rebuild image, then open a shell
./sandbox.sh up              # start in the background
./sandbox.sh status          # docker compose ps
./sandbox.sh logs            # follow container logs
./sandbox.sh down            # stop/remove container; keeps volumes/logins
docker compose up -d --force-recreate   # after editing .env
```

`./sandbox.sh help` lists all commands. No test suite in this repo. Ticket
workflow inside the sandbox: `/plan-item <issue-url>` then
`/implement-item <issue-url>`.

## Conventions

- LF line endings are enforced by `.gitattributes` (`* text=auto eol=lf`;
  `*.ps1` stays CRLF); `sandbox.sh` must stay executable.
- Skills/commands in `config/` take effect after restarting `claude`/`opencode`
  or the container; no rebuild needed. Dockerfile changes need `./sandbox.sh build`.
- `/plan-item` only researches and posts a plan comment marked
  `<!-- plan-item:v1 -->`; `/implement-item` requires that marker, works on a
  feature branch, opens a PR. Never commit to `main`; human reviews/merges.
- Both skills have `disable-model-invocation: true` (explicit invocation only).
- One session per ticket; run `/init` once per project in `workspace/`.
- `config/opencode/opencode.jsonc` contains only `$schema`; its comment about
  OpenCode 1 rejecting V2 `permissions` is stale (only OpenCode 2 runs).
  Adding V2 rules is an open TODO; the container is the security boundary.
- Do not put unrelated secrets in `.env`; the model can read it.
- OpenCode is pinned in the Dockerfile (installer
  `https://opencode.ai/v2/install`); the real binary is
  `/home/dev/.opencode/bin/opencode`, symlinked as `/usr/local/bin/opencode`
  and `opencode2`.
- Logins/caches live in named volumes (`sandbox-claude`, `sandbox-opencode`,
  package caches); `docker compose down -v` deletes them.

## Current state (2026-11-02)

Working: Docker Engine 29.9.2 in WSL 2 (Ubuntu 26.04, user `user2`), image
`sandbox-dev:latest`, container `sandbox-dev` running from it. In the container:
OpenCode (version pinned in the Dockerfile), Claude Code 2.1.316, PHP 8.5.12,
Node 22.23.4, user `dev`, working dir `/workspace`; HANDOVER also reports
Composer 2.11.1, Bun 1.4.4 and gh 2.103.3. Docker Desktop is not installed (by decision).

`.env` exists (mode 600) but holds placeholders only: `USER_UID`/`USER_GID`,
`GIT_USER_NAME`/`GIT_USER_EMAIL`, the GitHub token and provider keys are empty.
No provider is authenticated yet (`opencode auth list` -> "No authenticated
integrations"). The repo git identity is a repo-local placeholder
(`user2 <user2@localhost>`).

Git: branch `main` (renamed from `master`), tracking `origin/main`
(`https://github.com/XZ6Hte/sandbox.git`; `gh` is authenticated on the WSL host,
not in the container). History: `4a1cfd5 "Initial commit"` (GitHub README),
`5b30fa5 "the box"`, `b94762e "Add AGENTS.md and CLAUDE.md"`, merge `44cb4ad`
(unrelated histories, local README kept); 26 tracked files, `AGENTS.md` and
`CLAUDE.md` included. The old remote branch `master` was deleted on GitHub
(only `main` remains).

## Open TODOs

- Fill `.env`: git identity, GitHub token, optionally one provider key.
- Log in to OpenCode and Claude Code inside the container (or set a key).
- Decide GitHub identity: machine user + fine-grained token (recommended,
  Option A) vs GitHub App (Option B). For B the private key must stay on the
  host (mode 600) - only short-lived installation tokens may enter the
  container. Details in `TODO.md`.
- Prerequisites for either: clone target repo into `workspace/<name>`, create a
  ruleset (PR + 1 human approval, no force push, no bypass for the bot), store
  the credential in `.env`, recreate the container, verify with `gh auth status`
  and a test branch/PR.
- Optional: bump the pinned OpenCode version in the Dockerfile; add V2
  `permissions` to `opencode.jsonc`; BuildKit cache mounts.
