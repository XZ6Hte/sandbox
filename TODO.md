# TODO

Captured 2026-11-01, for later.

## GitHub identity for the sandbox

Decision pending: **machine user (recommended)** or **GitHub App**.

Context:

- The sandbox repository is at `/home/user2/projects/sandbox` (git, branch
  `main`, remote `origin` = `https://github.com/XZ6Hte/sandbox.git`).
- The container only sees `/workspace`; clone the target project there before
  anything else.
- `gh` is not installed on the host, only inside the container. Account-level
  steps happen in a browser.
- A GitHub App needs a private key. If that key is mounted into the sandbox, the
  security benefit is lost — the agent runs as root with network access and can
  read it. The key must stay on the host, with only short-lived installation
  tokens entering the container.

### Prerequisites (both options)

- [ ] Clone the target repository into `workspace/<name>` (currently only
      `.gitkeep`).
- [ ] Create a ruleset on the target repository: require a pull request,
      require 1 human approval, dismiss stale approvals, require conversation
      resolution, block force pushes, restrict deletions. Add required status
      checks if CI exists.
- [ ] Make sure neither the machine user nor the App is in the ruleset's
      bypass list.
- [x] Store the credential in `.env` (mode 600, gitignored) and recreate the
      container: `docker compose up -d --force-recreate`.
- [ ] Verify inside the sandbox: `gh auth status`, push a test branch, open a
      test PR, confirm `main` rejects direct pushes.

### Option A — machine user with fine-grained token (recommended)

Why: works with the existing `GH_TOKEN` → `gh` + `git credential.helper`
design, no hourly expiry, simplest to operate. Trade-off: long-lived token,
consumes a seat on paid org plans, commits attributed to the machine account.

- [ ] Create the machine-user account and give it access to the selected
      repositories (collaborator or team).
- [ ] Create a fine-grained personal access token for that account, restricted
      to selected repositories:
      - Contents: read/write (clone, branch, push)
      - Issues: read/write (`/plan-item` comments)
      - Pull requests: read/write (open/update PRs)
      - Workflows: read/write only if the agent may change `.github/workflows/*`
      - Metadata: read (automatic)
- [ ] Set an expiry (e.g. 90 days) and a calendar reminder to rotate.
- [ ] Put it in `.env` as `GITHUB_PERSONAL_ACCESS_TOKEN`.
- [ ] Rotate later by editing `.env` and recreating the container.

### Option B — GitHub App

Why: short-lived installation tokens (~1 h), per-repository installation, bot
identity, no seat. Cost: JWT minting and token refresh, plus a `gh` wrapper
because `gh` reads `GH_TOKEN` only at start.

- [ ] Create the App under the account or org.
- [ ] Permissions: Contents, Issues, Pull requests → read/write; Metadata →
      read; Workflows → read/write only if needed. Nothing else.
- [ ] Install it on the selected repositories only.
- [ ] Generate the private key once and save it on the host at
      `~/.config/sandbox/github-app.pem` (mode 600). Never commit it and never
      copy it into the image or `.env`.
- [ ] Record the App ID and installation ID in a host-side config file.
- [ ] Add `scripts/github-app-token.sh` on the host: build a JWT
      (`openssl dgst -sha256 -sign`), exchange it at
      `POST /app/installations/<id>/access_tokens`, print the token.
- [ ] `sandbox.sh`: mint a token at start, write it to `.runtime/gh-token`
      (mode 600, gitignored), refresh every ~50 minutes while the shell is
      open.
- [ ] Mount `.runtime/gh-token` into the container read-only.
- [ ] Inside the container, add a `gh` wrapper and a git credential helper that
      read the token file per invocation (do not rely on a fixed `GH_TOKEN`).
- [ ] Set git author/committer to the App bot identity shown by GitHub
      (`<slug>[bot]`, bot noreply email).
- [ ] Test: push a branch, open a PR, wait past expiry and confirm the next
      call still works.
- [ ] Confirm the App is not in the ruleset bypass list and cannot approve PRs.

## Later, unrelated

- [ ] Fill `.env`: git identity and GitHub token (currently placeholders).
- [ ] Log in to OpenCode and Claude Code inside the container.
- [x] Make the first commit of the sandbox repository (done; remote `origin` set up).
- [ ] Optional: OpenCode 2.1.2 → 2.2.5 (bump the pin in the Dockerfile).
- [ ] Optional: model right-sizing — cheap model for an `explore` subagent,
      strong model for `/plan-item`.
- [ ] Optional: BuildKit cache mounts so image rebuilds do not re-download.
