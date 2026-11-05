# AGENTS.md — working on the sandbox repository

Instructions for any AI coding agent doing work in this repository (host side).
This repo is the sandbox's source; the rules for agents running *inside* the
container are separate — see the pointer at the end.

## What this repo is and is not

- A Docker-based sandbox for agentic coding (PHP/Laravel, Node, Bun, `gh`,
  OpenCode 2, Claude Code) plus two workflow skills: `plan-item` and
  `implement-item`.
- **Tooling only — no application code.** Real projects live in `workspace/`,
  which is a bind mount, git-ignored in practice (only `workspace/.gitkeep` is
  tracked), and must never be edited from here.
- Git: branch `master`, single commit `5b30fa5 "the box"`, no remote.
  Note: `HANDOVER.md` and `TODO.md` still say the repo has no commits — that is
  stale. Do not repeat that claim, and do not "fix" those docs casually.

## Layout (verified paths)

| Path | Role |
| --- | --- |
| `Dockerfile` | Image recipe (base `php:8.5-cli-bookworm`, OpenCode version pinned there) |
| `compose.yaml` | Service `sandbox`, image `sandbox-dev:latest`, container `sandbox-dev`, mounts and volumes |
| `sandbox.sh` / `sandbox.ps1` | Launchers for Linux/WSL and Windows |
| `.env.example` → `.env` | Template; `.env` is created by `sandbox.sh`, mode 600, git-ignored |
| `scripts/entrypoint.sh` | Container entrypoint (git identity, safe.directory, gh helper) |
| `scripts/install-docker-wsl.sh` | Installs Docker Engine inside WSL 2 |
| `config/skills/{plan-item,implement-item}/SKILL.md` | Single source of truth for the two workflows |
| `config/commands/{plan-item,implement-item}.md` | OpenCode slash-command wrappers for the skills |
| `config/memory/AGENTS.md` | Sandbox-wide rules, mounted read-only into both agents |
| `config/claude/settings.json` | Claude Code permissions |
| `config/opencode/opencode.jsonc` | OpenCode config |
| `workspace/` | Bind-mounted at `/workspace` — the only host path inside the container |

## Commands

From `sandbox.sh` (run in the WSL distro where Docker lives):

| Command | Does |
| --- | --- |
| `./sandbox.sh` or `./sandbox.sh run` | Build if needed, start container, open shell |
| `./sandbox.sh exec <cmd...>` | Run one command inside the container |
| `./sandbox.sh build` | Rebuild image and open shell |
| `./sandbox.sh up` / `down` | Start in background / stop and remove container (volumes kept) |
| `./sandbox.sh status` / `logs` | Container state / follow logs |

After changing `.env`, recreate the container so the new env is picked up:
`docker compose up -d --force-recreate`. Logins and package caches live in
named volumes and survive `down` and rebuilds; `docker compose down -v`
deletes them.

**Validation — there is no test suite and no linter for this repo.** Before
committing, check the things you touched, for example:

- `bash -n sandbox.sh` (and any other edited shell script; `scripts/*.sh` too)
- `docker compose config` after touching `compose.yaml` or `.env.example`
- JSON parsing for `config/claude/settings.json`, JSONC-aware check for
  `config/opencode/opencode.jsonc`, YAML parsing for `compose.yaml`
- `scripts/install-docker-wsl.sh` and `sandbox.ps1`: syntax check only unless
  you can test them in a real WSL/Windows environment

## Conventions and hard rules

- LF line endings only; keep `sandbox.sh` executable; use `sandbox.ps1` on
  Windows. `.gitattributes`/`.editorconfig` exist for this.
- No secrets in git. `.env` is git-ignored; the model can read it inside the
  container anyway, so never put unrelated secrets there either.
- A GitHub App private key (if that option is chosen) stays on the host —
  never in the image, never in `.env`, never committed.
- Changing `Dockerfile`, `compose.yaml` build args or `.env` requires an image
  rebuild and/or container recreate. Changing files under `config/` (skills,
  commands, memory) only takes effect after restarting `opencode` / `claude`
  or the container — no rebuild.
- For target projects inside `workspace/`: never commit to `main`; one issue,
  one branch, one pull request. The human reviews and merges.

## Security model (short version)

The container is the boundary: no Docker socket, no host home directory, no
SSH agent; the only writable host path is `workspace/` (everything else from
this repo is mounted read-only). Passwordless sudo inside the container is a
convenience for tool installs, not a boundary. `main` protection in target
repos is by instruction only here — real control is GitHub branch protection
plus a least-privilege token.

## Current state and open work

Sources of truth: `HANDOVER.md` (what was built, decisions) and `TODO.md`
(backlog) — with the caveat above about their stale "no commits" wording.
Verified current facts:

- Container `sandbox-dev` running image `sandbox-dev:latest`; inside: OpenCode
  (version pinned in the Dockerfile), Claude Code v2.1.318, PHP 8.5.12, Node v22.23.4, user `dev`.
- Host: Docker Engine 29.9.2 + Compose v5.6.1 in WSL 2 (Ubuntu 26.04, user
  `user2`).
- `.env` exists with placeholders only; no agent logins or provider
  integrations yet (`opencode auth list` is empty).

Open work (details in `TODO.md`):

- **GitHub identity decision** — machine user + fine-grained token
  (recommended) vs GitHub App. A fine-grained token (Contents, Issues, Pull
  requests read/write on selected repos) fits the existing `GH_TOKEN` design.
  A GitHub App's private key must stay on the host with only short-lived
  installation tokens entering the container.
- Fill `.env` (git identity, GitHub token) and log in to OpenCode/Claude Code
  inside the container.
- Optional: bump the OpenCode pin, add OpenCode 2 `permissions` rules, model
  right-sizing, BuildKit cache mounts.

## How to work in this repo

- Read `README.md`, `HANDOVER.md` and `TODO.md` before changing behaviour;
  they explain why things are the way they are.
- Ask before account-level or security-relevant changes (tokens, identities,
  mounts, sudo, network exposure).
- Keep changes small and consistent with existing style; this repo is
  deliberately minimal.
- Do not restructure the mounts or volumes without discussing it — both agents
  depend on the exact `compose.yaml` mount table.
- Never edit anything under `workspace/` from this repo's tooling work; that
  directory belongs to real user projects.

## Container-side rules are elsewhere

`config/memory/AGENTS.md` is the working agreement for agents running inside
the sandbox (mounted read-only as OpenCode's global `AGENTS.md` and Claude's
`CLAUDE.md`). It does not govern edits to this repository. Do not duplicate or
modify it here.
