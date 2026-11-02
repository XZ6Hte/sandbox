# Sandbox rules

## Start here

Before the first task of a session, read `/home/dev/TODO.md` (the sandbox
backlog) and check whether the request matches an open item. Do not act on
account-level or security-relevant items without the user's explicit go-ahead.

You work inside a disposable Linux container. Only `/workspace` is visible from
the host and only its contents survive outside the container. The user reviews
every change from the host.

## Working agreement

- Work only in `/workspace/<project>`. Do not edit files outside `/workspace`.
- One ticket per session. If the topic changes, ask the user to start a new
  session.
- Never commit to `main`. One issue, one branch, one pull request.
- Ask before destructive or irreversible actions: `reset`, `clean`,
  `force-push`, migrations against real data.
- Never commit secrets. `.env` stays out of git.

## Reading efficiently

- Start with `rg` (or `git grep`) to locate code; do not read whole directories.
- Then read the files you will change and their tests, once.
- Skip `vendor/`, `node_modules/`, `storage/`, build output, lockfiles and
  minified assets.
- For broad "where is X handled?" questions, delegate to a subagent if one is
  available and ask for a `file:line` summary, not raw output.
- Read the project's `AGENTS.md` (or `CLAUDE.md`) first when it exists.

## Tickets

- `/plan-item <issue>` writes the plan to the issue and is read-only for code.
- `/implement-item <issue>` must read the plan comment
  (`<!-- plan-item:v1 -->`) and the files it names before writing code.
- Plan and later issue comments override this file for that ticket.

## Build and test

Detect commands from `composer.json`, `package.json` and CI config. Typical
Laravel:

- `composer install`
- `php artisan test`
- `vendor/bin/pint --test`
- `vendor/bin/phpstan analyse` (if configured)
- `bun run lint`, `bun run build`, `bun test` (if present)

Run the narrowest relevant check first, the full suite before opening a PR.

## Sandbox facts

- `gh` is authenticated via `GH_TOKEN`; `git` uses the gh credential helper.
- Network access exists; package installs are fine.
- `sudo` is passwordless inside the container; use it only for system packages.
