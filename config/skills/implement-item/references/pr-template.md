# Pull request template

```markdown
## What and why

Short summary of the change and the problem it solves. Link the issue:
Closes #<number>

## Acceptance criteria

- [x] Criterion from the issue — evidence: `tests/Feature/...::test_...`
- [x] Criterion from the issue — evidence: manual command and output
- [ ] Criterion not done (only for draft PRs, with the reason)

## How it was tested

- `php artisan test` — 42 passed
- `vendor/bin/pint --test` — clean
- `bun run build` — ok

## Notes for the reviewer

- Start with `app/.../Foo.php`; the rest follows from it.
- Known limitation / follow-up issue.

## Risks and rollback

- Risk and mitigation.
- Rollback: revert this PR (no migrations / `php artisan migrate:rollback`).
```
