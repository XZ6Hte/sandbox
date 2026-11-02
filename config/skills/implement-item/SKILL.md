---
name: implement-item
description: Implement a planned GitHub issue in the sandbox. Creates a branch, writes code and tests, pushes and opens a pull request. Requires a plan comment written by plan-item. Invoke only when the user runs /implement-item.
disable-model-invocation: true
---

# Implement a work item

You are implementing **one** planned GitHub issue. The plan was written by
`/plan-item` and lives as a comment on the issue. You work on a branch and
deliver a pull request. You never touch `main`.

## Preconditions — check in this order, stop if one fails

1. Resolve the issue (URL, `owner/repo#123`, `#123`). Read it including all
   comments: `gh issue view <number> --json number,title,body,comments,url`.
   On a long thread, fetch only the plan with:

   ```sh
   gh issue view <number> --json comments \
     --jq '.comments[] | select(.body | contains("<!-- plan-item:v1 -->")) | .body'
   ```

2. Find the plan comment containing `<!-- plan-item:v1 -->`. If there is none,
   stop and ask the user to run `/plan-item` first. Do not invent a plan.
   Read its **Files to touch** and **Test plan** sections, then open exactly
   those files and their tests. The plan is the map; do not rediscover the
   repository.
3. Read every comment that came *after* the plan. Later human decisions
   override the plan. If they contradict the plan, ask before coding.
4. `git status --porcelain` must be empty. If it is not, stop and show the
   changes. Never stash, reset, clean or discard work without explicit
   permission.
5. Update the default branch: `git fetch origin`, `git switch main`,
   `git pull --ff-only`. If `main` does not exist, use the repository default
   branch. Never develop on the default branch.

## Implementation

1. Create a branch: `feat/<number>-<short-slug>` for features,
   `fix/<number>-<short-slug>` for bugs. One issue, one branch, one PR.
2. Read `AGENTS.md` / `CLAUDE.md` and follow the repository's conventions
   before writing code. For anything the plan leaves open, search with `rg`
   first and read only the files involved; delegate broad searches to a
   subagent if one is available.
3. Implement the plan. Small, reviewable commits in conventional-commit style
   (`feat(api): ...`, `test: ...`, `docs: ...`), each referencing `#<number>`.
4. Add or update tests for **every** acceptance criterion. Do not delete
   existing tests and do not weaken assertions to make a suite pass.
5. Run the project's checks. Detect the real commands from `composer.json`
   (`scripts`), `package.json` (`scripts`) and CI config; typical Laravel:
   - `php artisan test` (or `vendor/bin/pest` / `vendor/bin/phpunit`)
   - `vendor/bin/pint --test`
   - `vendor/bin/phpstan analyse` / `vendor/bin/psalm` when configured
   - `bun run lint`, `bun run build`, `bun test` when present
   Fix failures instead of skipping or disabling checks.
6. If the plan turns out to be wrong or incomplete: stop, explain what you
   found, and ask. You may add a comment to the issue describing the finding.
   Do not expand the scope silently.
7. Never commit secrets, `.env` files, `vendor/`, `node_modules/`, build
   artifacts or editor state.

## Pull request

1. Push the branch: `git push -u origin <branch>`.
2. Open the PR with the body from `references/pr-template.md`:

   ```sh
   gh pr create --base main --head <branch> \
     --title "<type>(<scope>): <summary> (#<number>)" \
     --body-file -
   ```

3. The body must link the issue with `Closes #<number>` and tick the
   acceptance criteria with evidence (test name, command output).
4. Open a draft PR if anything is intentionally incomplete. Never mark a PR
   ready while tests fail.
5. Never force-push, never merge, never approve your own work.

## Report

Reply with: the PR URL, the checks you ran with their result, the parts a
reviewer should look at first, and any open question. Stop there; the human
reviews and merges.
