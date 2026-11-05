# TODO

Captured 2026-11-01, for later.

## GitHub identity for the sandbox

Decision (2026-11-02): **Option A, machine user `de-fraengi`**. Option B
(GitHub App) stays documented below as an alternative.

Roles (2026-11-05): `de-fraengi` develops inside the container (its token is
the only one in `.env`); `XZ6Hte` reviews and approves in the browser. The
approver's token must never be in the container. `de-fraengi` has Write on
`XZ6Hte/satzart`, no admin. The token is a classic PAT with scope `repo` only
(a fine-grained token was not tried), 90 days, expires 2027-02-03. Rulesets on
private repos need GitHub Pro on the owner account (`XZ6Hte`, bought
2026-11-05).

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

- [x] Clone the target repository into `workspace/<name>` (done:
      `workspace/satzart`).
- [x] Create a ruleset on the target repository: require a pull request,
      require 1 human approval, dismiss stale approvals, require conversation
      resolution, block force pushes, restrict deletions (done on
      `XZ6Hte/satzart`: ruleset `main-protect`, id 26631397; the sandbox repo
      itself stays at 0 approvals, see open items). Add required status
      checks if CI exists.
- [x] Make sure neither the machine user nor the App is in the ruleset's
      bypass list (empty on `satzart`).
- [x] Store the credential in `.env` (mode 600, gitignored) and recreate the
      container: `docker compose up -d --force-recreate`.
- [x] Verify inside the sandbox: `gh auth status`, push a test branch, open a
      test PR, confirm `main` rejects direct pushes (done 2026-11-05: logged in
      as `de-fraengi`; direct push to `main` rejected; test PR #26 showed
      REVIEW_REQUIRED and was closed unmerged).

### Open items (2026-11-02)

- [x] Merge PR #1 (`todo-env-done`): merged 2026-11-05 (squash, df3224e).
      Ruleset `main-protect` now has Required approvals = 0, no bypass actors,
      PR still required, force-push and deletion blocked.
- [ ] Optional: restore Required approvals to 1 in the sandbox repo's ruleset
      `main-protect` (`/rules/26386895`). Left at 0 on purpose: the agent works
      in `satzart`, not here, and a solo author cannot approve their own PR.
- [x] Add `de-fraengi` as collaborator (write) on the target repo
      (`XZ6Hte/satzart`, accepted 2026-11-05).
- [x] Verify token expiry/permissions of the `de-fraengi` token: classic,
      scope `repo`, expires 2027-02-03 16:46 UTC. Reaches only repos
      `de-fraengi` was invited to.
- [x] Log in to Claude Code inside the container (reported by the user
      2026-11-05).
- [x] Log in to OpenCode inside the container (done: `opencode auth list`
      shows Anthropic stored plus `ANTHROPIC_API_KEY` from the environment;
      OpenCode is v2.2.5).
- [ ] `OPENAI_API_KEY` in `.env` is empty (optional).
- [ ] Note: Claude Code and OpenCode probably authenticate with
      `ANTHROPIC_API_KEY` from `.env` (no `~/.claude/.credentials.json`), so
      usage is billed per API call and the agent can read the key: use a key
      with a spending limit.
- [ ] Note: `/home/dev/.claude.json` is not in a volume and is lost on
      `--force-recreate`; Claude Code may ask for its first-run setup again.
- [ ] Always work on feature branches; direct pushes to `main` are rejected.
- [x] Replace the `.env` token with one from `de-fraengi`, recreate the
      container, `gh auth status` shows `de-fraengi` (done 2026-11-05).
- [ ] Revoke the old `XZ6Hte` token (it saw four repos, expires 2027-01-31) on
      GitHub: Settings → Developer settings.
- [ ] Set a calendar reminder for rotation before 2027-02-03.
- [ ] Optional: delete the disabled, empty ruleset `Protect` (id 26316341) on
      `satzart`; it is superseded by `main-protect`.

#### Audit 2026-11-05 (historical, findings below were fixed the same day)

Resolution: `.env` now holds the `de-fraengi` token (classic, `repo`, expires
2027-02-03); `satzart` has an active ruleset with 1 required approval and no
bypass. Open: revoke the old `XZ6Hte` token.

- The container's `GH_TOKEN` authenticates as `XZ6Hte` (owner account), NOT the
  machine user `de-fraengi`. It is presumably a fine-grained PAT (no
  `X-OAuth-Scopes` header), expires 2027-01-31 17:54 UTC.
- The token can access four repos (`XZ6Hte/sandbox`, `XZ6Hte/TV`,
  `XZ6Hte/XZ6Hte`, `XZ6Hte/BTC-AG.com`); the owner account has ADMIN on each.
  The token's individual permission grants were not checked. This is broader
  than the intended "selected repositories only" scope. (The agent can read
  `.env`, so this is the blast radius.)
- With 0 required approvals and an owner token in the container, the agent can
  open and merge its own PRs into `main`; "human reviews/merges" is a
  convention only, not enforced. Until the token is replaced, check that it
  lacks Administration permission (otherwise it can also change the ruleset).
- `de-fraengi` is not a collaborator on XZ6Hte/sandbox and has no pending
  invitation.
- `workspace/` contains only `.gitkeep` (no target repo cloned yet).
- Ruleset `main-protect`: active, 1 ruleset, 0 approvals, no bypass.

### Option A — machine user with fine-grained token (recommended)

Why: works with the existing `GH_TOKEN` → `gh` + `git credential.helper`
design, no hourly expiry, simplest to operate. Trade-off: long-lived token,
consumes a seat on paid org plans, commits attributed to the machine account.

- [x] Create the machine-user account (`de-fraengi`).
- [x] Give it access to the selected repositories (collaborator or team):
      `XZ6Hte/satzart`, Write.
- [x] Create a personal access token for that account. Done as a classic PAT
      with `repo` only. A fine-grained token would be preferable if it can
      select a repository owned by another user (not tried); if so, use:
      - Contents: read/write (clone, branch, push)
      - Issues: read/write (`/plan-item` comments)
      - Pull requests: read/write (open/update PRs)
      - Workflows: read/write only if the agent may change `.github/workflows/*`
      - Metadata: read (automatic)
- [x] Set an expiry: 90 days (2027-02-03). Calendar reminder: still open.
- [x] Put it in `.env` as `GITHUB_PERSONAL_ACCESS_TOKEN` (now the `de-fraengi`
      token).
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

- [x] Fill `.env`: git identity (`de-fraengi`, noreply address) and GitHub
      token (done 2026-11-05).
- [x] Log in to OpenCode and Claude Code inside the container (done).
- [x] Make the first commit of the sandbox repository (done; remote `origin` set up).
- [x] OpenCode 2.1.2 → 2.2.5: the container already runs 2.2.5; check that the
      Dockerfile pin matches.
- [ ] Optional: model right-sizing — cheap model for an `explore` subagent,
      strong model for `/plan-item`.
- [ ] Optional: BuildKit cache mounts so image rebuilds do not re-download.
