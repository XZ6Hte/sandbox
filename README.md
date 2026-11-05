# Sandbox

A containerised development environment for agentic coding, modelled on the
c't article "Schluss mit Vibe-Coding" (Jan Mahn, 2026-10-16). The coding agent
runs inside the container; on your machine only this repository and the
bind-mounted `workspace/` exist for it.

Included:

- PHP 8.5 with the extensions Laravel needs, Composer
- Node.js 22, npm, Bun
- Git, GitHub CLI (`gh`), ripgrep, jq, sqlite3
- OpenCode 2 and Claude Code
- Two workflow skills: `/plan-item` and `/implement-item`

## Requirements

- Docker Engine or Docker Desktop with `docker compose` v2
- A GitHub token (only needed for issue/PR work)
- An account or API key for at least one model provider

### WSL 2

Docker can run either through Docker Desktop's WSL integration or as Docker
Engine inside the distro. The second option keeps everything in Linux and uses
the paths in this repository unchanged:

```sh
sudo bash scripts/install-docker-wsl.sh "$USER"
```

The script installs `docker-ce` plus the Compose plugin, enables the systemd
service, and adds you to the `docker` group. Open a new terminal afterwards so
the group applies. It needs `systemd=true` under `[boot]` in `/etc/wsl.conf`.

## First run

```sh
cd sandbox
./sandbox.sh          # Windows: .\sandbox.ps1
```

On first start the script checks Docker, creates `.env` from `.env.example`,
builds the image and drops you into a shell inside the container. Edit `.env`
first if you want to skip the warnings:

| Variable | Purpose |
| --- | --- |
| `USER_UID` / `USER_GID` | Host UID/GID, so files in `workspace/` keep your ownership |
| `GIT_USER_NAME` / `GIT_USER_EMAIL` | Identity for commits made in the sandbox |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `gh` access to issues and pull requests |
| `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` | Optional, instead of interactive login |

For the GitHub token, use a classic token with the `repo` scope only. A
fine-grained token (**read/write** on *Contents*, *Issues* and *Pull requests*)
works only if it can select the repository. Set an expiry, for example 90 days.

Without `read:org`, `gh pr edit` and `gh pr view --json ...` fail (they use
GraphQL). Change a pull request's body or base through the REST API instead:

```sh
gh api -X PATCH repos/<owner>/<repo>/pulls/<n> -f body="..."
```

## Logging in

Inside the sandbox:

- OpenCode: `opencode`, then `/connect`.
- Claude Code: `claude`, choose "Claude Account with subscription" (or an API
  key). Re-authenticate later with `/login`.
- `gh auth status` should show your token. If not, `GH_TOKEN` is empty in
  `.env`.

Logins are stored in Docker volumes (`sandbox-claude`, `sandbox-opencode`) and
survive restarts and rebuilds. `docker compose down -v` deletes them.
`/home/dev/.claude.json` is not in a volume and is lost when the container is
recreated, so Claude Code may show its first-run setup again.

## Working

Put projects in `workspace/`. That directory is the only host path the agent
can see, and it is where you should open your IDE.

New project, from inside the sandbox:

```text
Lege im Workspace ein neues Laravel-Projekt namens backend an.
```

Ticket workflow:

```text
/plan-item https://github.com/<owner>/<repo>/issues/1
/implement-item https://github.com/<owner>/<repo>/issues/1
```

`/plan-item` only researches and asks questions; it posts the agreed plan as
an issue comment marked `<!-- plan-item:v1 -->`. `/implement-item` requires
that marker, creates a feature branch, implements, tests, pushes, and opens a
pull request. Both skills forbid committing to `main`; the human reviews and
merges.

Two habits keep sessions cheap:

- **One session per ticket.** Start a new session when you switch topics; the
  plan comment is the handover between `/plan-item` and `/implement-item`.
- **Run `/init` once per project.** It writes an `AGENTS.md` (Claude Code reads
  `CLAUDE.md`) with build/test commands and conventions, so later sessions do
  not rediscover them. The sandbox-wide rules in `config/memory/AGENTS.md` are
  loaded on top of it.

## Layout

```text
.
├── Dockerfile                  image recipe
├── compose.yaml                mounts, env, volumes
├── sandbox.sh / sandbox.ps1    preflight checks + shell
├── .dockerignore               keeps files out of the build context
├── .env.example                template for .env (git-ignored)
├── AGENTS.md / CLAUDE.md       project notes for coding agents
├── HANDOVER.md                 state of the setup at handover
├── TODO.md                     open tasks and current setup notes
├── scripts/
│   ├── entrypoint.sh           git identity, safe.directory, gh helper
│   ├── rotate-token.sh         replace the GitHub token in .env (run on host)
│   └── install-docker-wsl.sh   install Docker Engine in WSL 2
├── config/
│   ├── skills/                 single source of truth for the workflows
│   │   ├── plan-item/SKILL.md
│   │   └── implement-item/SKILL.md
│   ├── commands/               OpenCode slash commands that load a skill
│   ├── memory/AGENTS.md        sandbox-wide rules (also Claude's CLAUDE.md)
│   ├── claude/settings.json    Claude Code permissions, default model (sonnet)
│   └── opencode/opencode.jsonc OpenCode config
└── workspace/                  your projects (bind mount)
```

`config/memory/AGENTS.md` is mounted read-only as `~/.config/opencode/AGENTS.md`
and `~/.claude/CLAUDE.md`, so both agents start with the same working agreement,
reading rules and build commands.

The Composer, npm and Bun caches live in named volumes (`sandbox-composer-cache`,
`sandbox-composer-config`, `sandbox-npm-cache`, `sandbox-bun-cache`), so
recreating the container does not re-download dependencies.

`config/skills` is mounted twice:

- `~/.claude/skills` — Claude Code turns each skill into `/plan-item` and
  `/implement-item` directly.
- `~/.config/opencode/skills` — OpenCode skills are not slash commands, so
  `config/commands` adds the `/plan-item` and `/implement-item` wrappers.
  `disable-model-invocation: true` keeps OpenCode and Claude from invoking them
  on their own; the descriptions also ask for an explicit slash command.

Changing a skill or command on the host takes effect after restarting
`opencode` / `claude` (or the container); no rebuild is needed.

## Models

The default model is `sonnet` (`config/claude/settings.json`). `/plan-item`
runs on Opus (`model: opus` in its skill, `model:` in the OpenCode command).
The OpenCode `explore` subagent runs on Haiku (`config/opencode/opencode.jsonc`);
Claude Code's built-in Explore agent already uses Haiku.

## Two accounts and approval

Development and approval are split across two GitHub accounts, for example:

- The agent works as a machine user (here `de-fraengi`); only its token is in
  the container.
- A human approver (here `XZ6Hte`) reviews and approves pull requests in the
  browser. The approver's token must never be in the container.
- To rotate the machine user's token, run `scripts/rotate-token.sh` on the
  host, then revoke the old token on GitHub.

See `TODO.md` for the current setup.

## Security model

- The container is the boundary: no Docker socket, no host home directory, no
  SSH agent. The only writable host path is `workspace/`.
- The container user has passwordless `sudo`. That keeps `apt-get install` and
  other tool installs working while the agent is inside a disposable
  container. It is not a boundary against a kernel or Docker escape; if you
  need that, run the sandbox in a VM.
- The model can read everything inside the container, including `.env` and
  your provider keys. Do not put unrelated secrets in `.env`.
- Protect `main` on GitHub, not just by instruction. For example, a ruleset on
  the target repository: pull request required, 1 approval, the last pusher
  cannot approve, no bypass actors, required status checks. Rulesets on private
  repositories need GitHub Pro on the owner account.
- The agent's token belongs to a dedicated machine user with the minimum scope
  (`repo`); the approver approves in the browser (see "Two accounts and
  approval"). `TODO.md` describes the current setup.

## Common commands

```sh
./sandbox.sh                 # start and open a shell
./sandbox.sh exec opencode   # run one command inside
./sandbox.sh build           # rebuild after changing the Dockerfile
./sandbox.sh status
./sandbox.sh logs
./sandbox.sh down            # keep volumes and logins
```

## Troubleshooting

**`permission denied` on files in `workspace/`** — the UID/GID in `.env` do
not match your host user. Set them to the output of `id -u` / `id -g`, then
`./sandbox.sh build`.

**Docker daemon not reachable** — start Docker Desktop/Engine. On Linux, add
your user to the `docker` group and log in again.

**`permission denied` on `/var/run/docker.sock`** — your shell started before
the `docker` group was added. Open a new WSL terminal; the group is applied at
login.

**`gh` cannot comment** — check `gh auth status`; the token needs Issues and
Pull request write access on that repository. Private repositories also need
Contents read access.

**Claude login expired** — start `claude` and run `/login`.

**Build fails at the OpenCode installer** — the image installs OpenCode 2 from
`https://opencode.ai/v2/install` and pins the version in the Dockerfile. Bump or
drop `--version` there to move to a newer release. OpenCode 1 uses the other
installer (`https://opencode.ai/install`), which refuses 2.x versions. The
binary lands in `/home/dev/.opencode/bin/opencode` and is symlinked to
`/usr/local/bin/opencode`.

**Windows line endings** — keep the repository on LF (`git config core.autocrlf
input`); `sandbox.sh` must stay executable. Use `sandbox.ps1` on Windows
instead.
