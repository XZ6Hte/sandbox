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
- Git: branch `main`, remote `origin` = `https://github.com/XZ6Hte/sandbox.git`
  (`main` tracks `origin/main`). Read counts live: `git ls-files | wc -l`,
  `git log --oneline main | wc -l` (2026-11-05, before PR #12: 27 files,
  16 commits on `main`).
  `HANDOVER.md` is a dated log, so older statements in it can be outdated.
- Purpose: modelled on the c't article "Schluss mit Vibe-Coding" (Jan Mahn,
  2026-10-16). The coding agent runs inside the container; only the
  bind-mounted `workspace/` is a writable host path (selected `config/` files
  are mounted read-only).

## Layout (verified paths)

| Path | Role |
| --- | --- |
| `Dockerfile` | Image recipe (base `php:8.5-cli-bookworm`, OpenCode version pinned there) |
| `compose.yaml` | Service `sandbox`, image `sandbox-dev:latest`, container `sandbox-dev`, mounts and volumes |
| `sandbox.sh` / `sandbox.ps1` | Launchers for Linux/WSL and Windows |
| `.env.example` → `.env` | Template; `.env` is created by `sandbox.sh`, git-ignored, readable only by the owner and the local group `shared` |
| `.dockerignore`, `.editorconfig`, `.gitattributes`, `.gitignore` | Build context, editor and git hygiene (LF enforced; `*.ps1` stays CRLF) |
| `scripts/entrypoint.sh` | Container entrypoint (git identity, safe.directory, gh helper) |
| `scripts/install-docker-wsl.sh` | Installs Docker Engine inside WSL 2 |
| `scripts/rotate-token.sh` | Host-side: replaces the GitHub token in `.env` (hidden input), checks the login, recreates the container |
| `README.md` | Operational reference (setup, logins, daily use, troubleshooting) |
| `TODO.md` | Backlog and current decisions; mounted read-only as `/home/dev/TODO.md` |
| `HANDOVER.md` | Dated history of how the sandbox was built |
| `config/skills/{plan-item,implement-item}/` | Single source of truth for the two workflows (`SKILL.md` and `references/`) |
| `config/commands/{plan-item,implement-item}.md` | OpenCode slash-command wrappers for the skills |
| `config/memory/AGENTS.md` | Sandbox-wide rules, mounted read-only into both agents |
| `config/claude/settings.json` | Claude Code permissions and default model (`sonnet`) |
| `config/opencode/opencode.jsonc` | OpenCode config: `explore` subagent on Haiku; V2 `permissions` not set up (the container is the boundary) |
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
| `./sandbox.sh help` | Lists all commands |

After changing `.env`, recreate the container so the new env is picked up:
`docker compose up -d --force-recreate`. Logins and package caches live in
named volumes (in `compose.yaml` e.g. `sandbox-claude`; `docker volume ls`
shows them with the project prefix, e.g. `sandbox_sandbox-claude`) and survive
`down` and rebuilds; `docker compose down -v` deletes them.

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
- OpenCode is pinned in the Dockerfile (installer `https://opencode.ai/v2/install`);
  the binary is `/home/dev/.opencode/bin/opencode`, symlinked as
  `/usr/local/bin/opencode` and `opencode2`. Read the pinned and running versions
  live: `grep -i opencode Dockerfile`, `./sandbox.sh exec opencode --version`.
- Models: Claude Code defaults to `sonnet` (`config/claude/settings.json`);
  `plan-item` runs on Opus. OpenCode's `explore` subagent uses Haiku.
- Workflow skills: `/plan-item` only researches and posts a plan comment marked
  `<!-- plan-item:v1 -->`; `/implement-item` requires that marker, works on a
  feature branch and opens a PR. Both have `disable-model-invocation: true`
  (explicit invocation only). One session per ticket; run `/init` once per
  project in `workspace/`.
- A GitHub App private key (if that option is chosen) stays on the host —
  never in the image, never in `.env`, never committed.
- Changing `Dockerfile`, `compose.yaml` build args or `.env` requires an image
  rebuild and/or container recreate. Changing files under `config/` (skills,
  commands, memory) only takes effect after restarting `opencode` / `claude`
  or the container — no rebuild.
- For target projects inside `workspace/`: never commit to `main`; one issue,
  one branch, one pull request. The human reviews and merges.

## Security model (short version)

The container is the isolation boundary: no Docker socket, no host home
directory, no SSH agent; the only writable host path is `workspace/`
(everything else from this repo is mounted read-only). Passwordless sudo inside
the container is a convenience for tool installs, not a boundary.

Branch protection on GitHub is the second layer. Target repos get a ruleset on
`main`: pull request required, 1 approval, no force push, no bypass actors,
required status checks. Rulesets on private repos need GitHub Pro on the owner
account. The machine user `de-fraengi` develops in the container with its own
token (`.env`, classic PAT with the `repo` scope only); the human account `XZ6Hte` approves in the browser.
The approver's token never enters the container. Setup details and the current
state of this decision: `TODO.md`.

## Current state

Dated pointer, not a status board: as of 2026-11-05 the sandbox is set up and
logged in; open work and current decisions live in `TODO.md`, history in
`HANDOVER.md`. Read versions live instead of trusting any document:
`docker compose version`, `./sandbox.sh exec claude --version`,
`./sandbox.sh exec opencode --version`.

## How to work in this repo

- `main` of this repo takes pull requests only (ruleset `main-protect`);
  work on a branch such as `docs-<topic>`. Force-push is blocked; never do it.
- Edit a PR's body or base with `gh api -X PATCH repos/<owner>/<repo>/pulls/<n>`
  (`gh pr edit` fails with a GraphQL scope error because the token lacks `read:org`).
- Merge only after the human's explicit yes.
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
