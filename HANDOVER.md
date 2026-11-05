# Handover — Sandbox Build

## Update 2026-11-05

The sandbox is fully set up: `.env` is filled and the logins (Claude Code,
OpenCode) are done. The sections below are the history as of 2026-11-01;
open work is in [`TODO.md`](TODO.md), the detailed reference is `AGENTS.md`.

| Item (live values, 2026-11-05) | Value |
| --- | --- |
| Docker Compose | v5.7.0 |
| Claude Code (container) | 2.1.318 |
| OpenCode (container) | v2.2.5 |
| Image `sandbox-dev:latest` | 2.69 GB |

Volume names: `docker volume ls` shows them with the project prefix `sandbox_`
(e.g. `sandbox_sandbox-claude`); `compose.yaml` uses the short names.

Decisions of 2026-11-05 (details in `TODO.md`):

- Machine user `de-fraengi` develops in the container; `XZ6Hte` approves in the
  browser. The approver's token never enters the container.
- Rulesets (`main-protect`) protect `main`; they need GitHub Pro on `XZ6Hte`
  (bought 2026-11-05).
- Claude Code uses the subscription login (`/login`), not an API key.
- Models: Sonnet default, Opus for `/plan-item`, Haiku for OpenCode's `explore`.
- `scripts/rotate-token.sh` replaces the GitHub token in `.env` and recreates
  the container.
- `.env` is readable only by the owner and the local group `shared`.

---

Status at handover time: **working** (2026-11-01). Docker, image, container and both coding
agents are installed and verified. What was left then: personal data in
`.env` and the interactive logins (done since).

**Start guide:** see [`README.md`](README.md) — it is the operational reference
(requirements, first run, logins, daily commands, troubleshooting). This file
only records what was done, the current state and the open items.

---

## What was done

1. **Scaffolded the sandbox** — Dockerfile, Compose file, launcher scripts,
   env template, skills, command wrappers, entrypoint, README. Shell syntax,
   JSON/JSONC, YAML and a dry run against a Docker stub were validated.
2. **Checked Windows for Docker** — no Docker Desktop: no
   `C:\Program Files\Docker`, no `com.docker.service`, no `docker-desktop` WSL
   distro, no `docker.exe` in `PATH`, nothing in the uninstall registry.
3. **Installed Docker Engine inside WSL 2** instead — Ubuntu 26.04
   (`resolute`), official Docker apt repo, systemd service, `user2` added to
   the `docker` group. `hello-world` and container networking verified.
   Reproducible via `scripts/install-docker-wsl.sh`.
4. **Built and verified the image** — toolchain checked inside the container,
   skills and commands confirmed as loaded.
5. **Upgraded OpenCode to 2.x** — the V1 installer
   (`https://opencode.ai/install`) refuses 2.x by design. The Dockerfile now
   uses `https://opencode.ai/v2/install`, pinned to **2.1.2**, with direct
   symlinks (`opencode` and `opencode2`). Verified: `opencode v2.1.2`.
6. **Checked Claude Code** — already installed natively on the host and in the
   image, both **2.1.316** (current latest); host install is logged in (Pro)
   and `claude doctor` reports no issues.
7. **Context-efficiency pass** — added `config/memory/AGENTS.md`, mounted as
   OpenCode's global rules and Claude's `CLAUDE.md`; `implement-item` now reads
   the plan's file list instead of rediscovering the repository; both skills
   search with `rg` first and delegate broad searches; Composer/npm/Bun caches
   are persisted in named volumes.

### Decisions worth knowing

- **Docker Engine in the distro, not Docker Desktop.** No Docker Desktop exists
  on this machine, and Linux paths in `compose.yaml` work unchanged.
- **One skill source, two agents.** The same `SKILL.md` serves Claude Code and
  OpenCode; only OpenCode needs the command wrappers.
- **Minimal OpenCode config (at handover time; `explore` now runs on Haiku).** OpenCode 1 rejected the V2 `permissions` array,
  so the config is `$schema` only. The container is the security boundary.
- **Passwordless sudo inside the container** so the agent can `apt-get install`
  tools. A convenience, not a security boundary.
- **`disable-model-invocation: true`** on both skills: they are only invoked
  explicitly, not by the model on its own.

## Current state (at handover time, 2026-11-01)

| Item | Value |
| --- | --- |
| Host | Windows 11 + WSL 2, Ubuntu 26.04, user `user2` (UID/GID 1000) |
| Docker Engine / Compose / buildx | 29.9.2 / v5.6.1 / 0.38.1 |
| Image | `sandbox-dev:latest`, 2.6 GB |
| Container | `sandbox-dev`, running |
| PHP / Composer | 8.5.12 / 2.11.1 |
| Node / Bun / gh | 22.23.4 / 1.4.4 / 2.103.3 |
| OpenCode (container, host) | v2.1.2 / v2.1.2 |
| Claude Code (container, host) | 2.1.316 / 2.1.316 |
| `.env` | present, mode 600, placeholders only (at handover time) |

Later: container OpenCode 2.2.5 / Claude Code 2.1.318, see `TODO.md`.

Named volumes: logins (`sandbox-claude`, `sandbox-opencode`) and package caches
(`sandbox-composer-cache`, `sandbox-composer-config`, `sandbox-npm-cache`,
`sandbox-bun-cache`). They survive restarts and rebuilds; `docker compose down
-v` deletes them.

## Open items (at handover time; current list: `TODO.md`)

1. Fill `.env` — git identity is still `Your Name <you@example.com>` and the
   GitHub token is empty.
2. Log in to OpenCode and Claude Code inside the container (README, "Logging
   in").
3. ~~Commit this repository~~ — done: branch `main` tracks `origin/main`
   (GitHub); the old remote `master` branch was deleted (only `main` remains).
4. ~~Optional: bump OpenCode from the pinned `2.1.2`~~ (done 2026-11-05:
   bumped to 2.2.5, see `TODO.md`)
5. Optional: add V2 `permissions` rules to `config/opencode/opencode.jsonc` now
   that only OpenCode 2 runs in the image.
6. Optional for real safety: branch protection on GitHub plus a dedicated
   machine account for the token.
