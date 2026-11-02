---
name: plan-item
description: Plan a GitHub issue before writing code. Research the repository, ask the open questions, define testable acceptance criteria and post the plan as an issue comment. Invoke only when the user runs /plan-item.
disable-model-invocation: true
---

# Plan a work item

You are planning **one** GitHub issue. This pass is read-only for the
repository: no branch, no edits to tracked files, no commits, no pull request.
The only write you may perform is a comment on the issue.

## Input

The work item is a GitHub issue URL, `owner/repo#123`, or `#123` / `123`.
If the argument is missing or ambiguous, stop and ask for the issue.

## Hard rules

- Never create or switch branches, never commit, push, or open a pull request.
- Never edit, close, label, or reassign the issue. Comment only.
- Do not modify tracked repository files. Reading, searching and `git log` are
  fine. Installing dependencies (`composer install`, `bun install`) is fine
  because the results are git-ignored; changing dependency manifests is not.
- Experiments run in `/tmp`, not in the repository. Running the existing test
  suite is allowed.
- Ask before anything destructive or irreversible.
- Do not start implementing, even if the fix looks trivial.

## Workflow

1. **Resolve the repository and issue.**
   - Parse the URL, or use `gh repo view --json nameWithOwner -q .nameWithOwner`.
   - If `gh` is not authenticated, run `gh auth status` and tell the user what
     is missing instead of guessing issue content.
   - Read the issue and its comments:
     `gh issue view <number> --json number,title,body,author,labels,comments,url`.

2. **Read the project's rules, selectively.** Start with `AGENTS.md` /
   `CLAUDE.md` and `README.md`. Open only what the task needs from `docs/`,
   `.editorconfig`, `composer.json` and `package.json`; check the test layout
   and the last ~10 commits when they inform conventions.

3. **Research the code.** Locate the routes, controllers, models, migrations,
   services, jobs and tests that the change touches. Search with `rg` first,
   then read the files you need in full when they are small, or the relevant
   range when they are large. Never read `vendor/`, `node_modules/` or build
   output. For broad "where is X handled?" questions, delegate to a subagent if
   one is available and ask for a `file:line` summary. Note existing patterns.

4. **Verify assumptions where cheap.** Run the relevant test file, check the
   framework version, look up the actual API of a library. Keep it read-only.

5. **Ask the decisions you cannot derive.** Ask at most five questions, in one
   batch, each with a recommended default. Typical: error handling, API shape
   and status codes, auth/authorization, persistence/migration, backwards
   compatibility, scope boundaries, UI vs API only. Wait for the answers
   before writing the plan.

6. **Write the plan** using `references/plan-template.md`. It must contain:
   goal, context, testable acceptance criteria, approach, concrete files to
   touch, test plan, risks and out-of-scope items, plus assumptions.

7. **Post the plan as an issue comment.** Use a heredoc with `--body-file -`:

   ```sh
   gh issue comment <number> --body-file - <<'EOF'
   <!-- plan-item:v1 -->
   ## Implementation plan
   ...
   EOF
   ```

   The first line `<!-- plan-item:v1 -->` is the marker `/implement-item`
   looks for. Never remove it. If a plan comment already exists, post a new
   revision and mention what changed; do not edit history.

8. **Report back.** Reply with the comment URL, a five-line summary and the
   next step: `/implement-item <issue-url>`. Then stop.

## Quality bar

- Acceptance criteria are observable: status code and body, database state,
  CLI output, rendered page. "It works" is not a criterion.
- Every criterion maps to at least one test.
- The plan names real files and functions, not "the service layer".
- The plan fits in one pull request. If not, propose a split.
- Every assumption is written down explicitly.
