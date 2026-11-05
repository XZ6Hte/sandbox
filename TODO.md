# TODO

Updated 2026-11-05. Agents read this file at session start (mounted read-only
at `/home/dev/TODO.md`), so keep it short and factual.

## Open

Tasks:

- [ ] Rotate the `de-fraengi` token before **2027-02-03** (calendar reminder is
      set): run `scripts/rotate-token.sh` on the host. It checks the new token
      belongs to `de-fraengi`, rewrites `.env`, recreates the container and
      verifies. Then revoke the old token on GitHub.
- [ ] `satzart`: decide the first task for the agent (postponed). No
      application code exists yet: no `composer.json`, no `artisan`; only
      `docs/`, `.ai/`, `.claude/`, `AGENTS.md`.
- [ ] `satzart`: decide whether to add the required status check `agent-guard`
      to ruleset `main-protect`. The workflow exists
      (`.github/workflows/agent-guard.yml`, jobs `hooks` and `immutable`);
      the T-065 close-out PR (decision "GitHub Pro: yes") is open there.

Optional:

- [ ] BuildKit cache mounts (`--mount=type=cache`) so image rebuilds do not
      re-download. Only if rebuilds become frequent.

## Rules and notes

- Always work on feature branches; direct pushes to `main` are rejected.
- Models: default `sonnet` (`config/claude/settings.json`); `/plan-item` uses
  Opus (`model: opus` in its skill, `model:` in the OpenCode command); the
  OpenCode `explore` subagent uses Haiku (`config/opencode/opencode.jsonc`).
  Claude Code's built-in Explore agent already runs on Haiku.
- OpenCode is pinned to 2.2.5 in the `Dockerfile` (takes effect on the next
  `./sandbox.sh build`; not tested with a rebuild yet).
- The token of the approver (`XZ6Hte`) must never be in the container; only the
  `de-fraengi` token is.
- The sandbox repo's own ruleset `main-protect` (`/rules/26386895`) stays at
  0 required approvals on purpose: the agent works in `satzart`, and a solo
  author cannot approve their own PR.
- Claude Code in the container uses the subscription login (`/login`). The API
  key in `.env` is commented out; if a key is used again, set a monthly
  spending limit in the Anthropic Console (the agent can read `.env`).
- `/home/dev/.claude.json` is not in a volume and is lost on `--force-recreate`;
  Claude Code may ask for its first-run setup again (the login stays).

## GitHub identity — current setup (done 2026-11-05)

Decision (2026-11-02): **machine user `de-fraengi`**. Option B (GitHub App) is
kept below as an alternative.

- `de-fraengi` develops inside the container; `XZ6Hte` reviews and approves in
  the browser.
- `de-fraengi` has Write on `XZ6Hte/satzart`, no admin. Other repos of `XZ6Hte`
  are public (read only).
- Token: classic PAT, scope `repo` only, expires 2027-02-03 17:28 UTC (a
  fine-grained token was not tried; it would need to select a repository owned
  by another user). Stored as `GITHUB_PERSONAL_ACCESS_TOKEN` in `.env`
  (mode 600, gitignored). Git identity in `.env`: `de-fraengi` with its
  noreply address.
- Ruleset `main-protect` on `satzart` (id 26631397): pull request required,
  1 approval, stale approvals dismissed, last pusher cannot approve,
  conversations resolved, force push and deletion blocked, no bypass actors.
  Rulesets on private repos need GitHub Pro on `XZ6Hte` (bought 2026-11-05).
- Verified in the container: `gh auth status` shows `de-fraengi`; a direct
  push to `main` is rejected; a test PR showed REVIEW_REQUIRED and was closed
  unmerged.
- Logged in to Claude Code and OpenCode in the container.

History:

- PR #1 merged 2026-11-05; the sandbox ruleset was set to 0 approvals.
- Audit 2026-11-05: the container token was the owner's (`XZ6Hte`) and could
  see four repos. Fixed the same day by replacing it with the `de-fraengi`
  token; the old token was revoked (reported by the user, not verifiable from
  here).
- Claude Code in the container first billed via API key (Opus 5.5); switched to
  the subscription login.
- Decided 2026-11-05: no OpenAI key (not needed); the empty ruleset `Protect`
  on `satzart` was deleted.

## Alternative: Option B — GitHub App (not planned)

Why: short-lived installation tokens (~1 h), per-repository installation, bot
identity, no seat. Cost: JWT minting and token refresh, plus a `gh` wrapper
because `gh` reads `GH_TOKEN` only at start. A GitHub App needs a private key;
if it is mounted into the sandbox the benefit is lost (the agent runs as root
with network access). The key must stay on the host, with only short-lived
installation tokens entering the container.

Steps, if it is ever wanted:

- Create the App under the account or org. Permissions: Contents, Issues, Pull
  requests read/write; Metadata read; Workflows read/write only if needed.
  Install it on the selected repositories only.
- Generate the private key once and save it on the host at
  `~/.config/sandbox/github-app.pem` (mode 600). Never commit it or copy it
  into the image or `.env`. Record the App ID and installation ID in a
  host-side config file.
- Add `scripts/github-app-token.sh` on the host: build a JWT
  (`openssl dgst -sha256 -sign`), exchange it at
  `POST /app/installations/<id>/access_tokens`, print the token.
- `sandbox.sh`: mint a token at start, write it to `.runtime/gh-token` (mode
  600, gitignored), refresh every ~50 minutes; mount it into the container
  read-only.
- In the container: a `gh` wrapper and a git credential helper that read the
  token file per invocation (do not rely on a fixed `GH_TOKEN`). Set git
  author/committer to the App bot identity (`<slug>[bot]`, bot noreply email).
- Test: push a branch, open a PR, wait past expiry and confirm the next call
  still works. Confirm the App is not in the ruleset bypass list and cannot
  approve PRs.
