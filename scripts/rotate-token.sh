#!/usr/bin/env bash
#
# Replace GITHUB_PERSONAL_ACCESS_TOKEN in .env with a new token, check that it
# authenticates as the expected GitHub user, recreate the container and verify.
#
#   scripts/rotate-token.sh [expected-login]     (default: de-fraengi)
#
# The token is read silently from the terminal and is never printed or passed
# on a command line. Run it on the host, from anywhere.
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

EXPECTED="${1:-de-fraengi}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '==> %s\n' "$*"; }

[ -f .env ] || die ".env not found in $(pwd)"
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"

printf 'New token for %s (input is hidden): ' "$EXPECTED"
IFS= read -rs TOKEN
echo
TOKEN="${TOKEN//[[:space:]]/}"

[ -n "$TOKEN" ] || die "empty input"
case "$TOKEN" in
    ghp_*|github_pat_*) ;;
    *) die "token must start with ghp_ or github_pat_ (a label such as 'sandbox: ' in front breaks it)" ;;
esac

note "Checking the token with GitHub"
RESPONSE="$(printf 'header = "Authorization: Bearer %s"\n' "$TOKEN" \
    | curl -fsS -K - https://api.github.com/user 2>/dev/null)" \
    || die "GitHub rejected the token (wrong, expired or revoked)"
LOGIN="$(printf '%s' "$RESPONSE" \
    | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["login"])')" \
    || die "unexpected answer from GitHub"

[ "$LOGIN" = "$EXPECTED" ] \
    || die "token belongs to '$LOGIN', expected '$EXPECTED'. .env was not changed."

note "Writing .env (other lines unchanged)"
TOKEN="$TOKEN" python3 -I - <<'PY'
import os, re
token = os.environ["TOKEN"]
lines = open(".env").read().split("\n")
out, done = [], False
for line in lines:
    if re.match(r"\s*GITHUB_PERSONAL_ACCESS_TOKEN\s*=", line):
        out.append("GITHUB_PERSONAL_ACCESS_TOKEN=" + token)
        done = True
    else:
        out.append(line)
if not done:
    out.append("GITHUB_PERSONAL_ACCESS_TOKEN=" + token)
open(".env", "w").write("\n".join(out))
PY
chmod 600 .env
unset TOKEN

note "Recreating the container"
docker compose up -d --force-recreate

note "Verifying inside the container"
docker compose exec sandbox gh api user --jq .login
note "Done. Revoke the old token on GitHub and update the calendar reminder."
