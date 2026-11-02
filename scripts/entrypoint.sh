#!/usr/bin/env bash
set -euo pipefail

# Git identity inside the sandbox, configured from .env.
if [ -n "${GIT_USER_NAME:-}" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# /workspace is a bind mount and is usually owned by the host user, which has a
# different UID inside the container. Without safe.directory git refuses to run.
git config --global --add safe.directory /workspace 2>/dev/null || true

# Prefer the gh credential helper whenever a token is present.
if [ -n "${GH_TOKEN:-}" ] \
    && ! git config --global --get credential."https://github.com".helper >/dev/null 2>&1; then
    git config --global credential."https://github.com".helper "!gh auth git-credential"
fi

exec "$@"
