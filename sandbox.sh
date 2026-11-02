#!/usr/bin/env bash
#
# Start the development sandbox and open a shell inside it.
#
#   ./sandbox.sh              build if needed, start, open a shell
#   ./sandbox.sh exec <cmd>   run a command inside the sandbox
#   ./sandbox.sh build        rebuild the image and open a shell
#   ./sandbox.sh up           start in the background
#   ./sandbox.sh down         stop and remove the container
#   ./sandbox.sh status       show container state
#   ./sandbox.sh logs         follow container logs
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SERVICE=sandbox

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

note() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

usage() {
    cat <<'EOF'
Usage: ./sandbox.sh [command] [args...]

Commands:
  run              build if needed, start the container, open a shell (default)
  exec <cmd...>    run a command inside the container
  build            rebuild the image and open a shell
  up               start the container in the background
  down             stop and remove the container (keeps volumes)
  status           show container state
  logs             follow container logs
  help             show this help

The first run creates .env from .env.example. Add your tokens there.
EOF
}

ensure_env_file() {
    if [ ! -f .env ]; then
        cp .env.example .env
        chmod 600 .env
        note "Created .env from .env.example. Add your tokens, then run this script again."
    fi
}

check_docker() {
    command -v docker >/dev/null 2>&1 \
        || die "Docker is not installed. See https://docs.docker.com/engine/install/"

    docker info >/dev/null 2>&1 \
        || die "The Docker daemon is not reachable. Start Docker (or Docker Desktop) and retry."

    docker compose version >/dev/null 2>&1 \
        || die "docker compose v2 is required."
}

check_env() {
    ensure_env_file

    if ! grep -Eq '^GITHUB_PERSONAL_ACCESS_TOKEN=.+' .env; then
        warn "GITHUB_PERSONAL_ACCESS_TOKEN is empty: /plan-item and /implement-item cannot read or comment on issues."
    fi

    if ! grep -Eq '^(ANTHROPIC_API_KEY|OPENAI_API_KEY|GEMINI_API_KEY)=.+' .env; then
        warn "No provider API key in .env. You can still log in interactively with 'opencode /connect' or 'claude'."
    fi
}

up() {
    docker compose up -d "$@"
}

exec_in() {
    docker compose exec "$SERVICE" "$@"
}

command="${1:-run}"
if [ $# -gt 0 ]; then
    shift
fi

case "$command" in
    help|-h|--help)
        usage
        exit 0
        ;;
esac

check_docker

case "$command" in
    run|shell)
        check_env
        up
        exec_in sh -l
        ;;
    run-cmd|exec)
        check_env
        [ $# -gt 0 ] || die "usage: ./sandbox.sh exec <command> [args...]"
        up
        exec_in "$@"
        ;;
    build|rebuild)
        check_env
        up --build
        exec_in sh -l
        ;;
    up)
        check_env
        up
        ;;
    down|stop)
        docker compose down
        ;;
    status|ps)
        docker compose ps
        ;;
    logs)
        docker compose logs -f "$SERVICE"
        ;;
    *)
        die "unknown command '$command' (try ./sandbox.sh help)"
        ;;
esac
