# Plan template

Copy this structure into the issue comment. Drop sections that truly do not
apply, but keep the marker and the acceptance criteria.

```markdown
<!-- plan-item:v1 -->
## Implementation plan

### Goal
One or two sentences: what the user gets when this ships.

### Context
Why the issue exists, what the current behaviour is, relevant constraints
(framework version, API contract, existing conventions).

### Acceptance criteria
- [ ] Observable outcome 1 (e.g. `GET /api/time` returns `200` with
      `{"time":"...","source":"ntp"}`)
- [ ] Observable outcome 2 (e.g. NTP failure returns `503` and logs a warning)
- [ ] No regression: existing suite still passes

### Approach
1. Step, with the file or module it happens in.
2. Step.
3. Step.

### Files to touch
| File | Change |
| --- | --- |
| `app/Http/Controllers/...` | ... |
| `routes/api.php` | ... |
| `tests/Feature/...` | ... |

### Test plan
- `tests/Feature/...`: case, assertion, edge case.
- Manual check (if any): command and expected output.

### Risks and rollback
- Risk, likelihood, mitigation.
- How to roll back (revert commit, feature flag, migration down).

### Out of scope
- Explicit non-goals, so the reviewer does not expect them.

### Assumptions and open questions
- Assumption made because it could not be derived from the repository.
- Question still open (if any). Implementation pauses until answered.
```
