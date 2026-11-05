# CLAUDE.md

Containerised dev environment for agentic coding (PHP/Laravel, Node, Bun, `gh`,
OpenCode 2, Claude Code, plus the skills `/plan-item` and `/implement-item`).
This repo is the sandbox tooling itself, with no application code; real projects
live in `workspace/`.

**Read `AGENTS.md` first. It is the single detailed reference** (layout,
commands, validation, rules, security model, how to work in this repo). Current
state and open work: `TODO.md`. This file only adds Claude-specific points.

## Claude-specific

- Both skills in `config/skills/` have `disable-model-invocation: true`; they
  run only when invoked explicitly (`/plan-item <issue-url>`, then
  `/implement-item <issue-url>`).
- Run `/init` once per project inside `workspace/`, not in this repo.
- Default model is `sonnet` (`config/claude/settings.json`); `/plan-item` runs
  on Opus (`model: opus` in its `SKILL.md`).
- Claude Code in the container uses the subscription login (`/login`), not an
  API key.
- `/home/dev/.claude.json` is not in a volume and is lost on
  `docker compose up -d --force-recreate`; `~/.claude` (the `sandbox-claude`
  volume) survives.
- `config/memory/AGENTS.md` is mounted as the container's `~/.claude/CLAUDE.md`;
  it is the rule set for agents inside the sandbox, not for work on this repo.
