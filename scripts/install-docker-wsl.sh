#!/usr/bin/env bash
# Install Docker Engine + Compose plugin inside a WSL 2 Ubuntu distro.
#
#   sudo bash scripts/install-docker-wsl.sh            # uses $SUDO_USER
#   sudo bash scripts/install-docker-wsl.sh user2      # explicit user
#
# Use this instead of Docker Desktop when you want Docker to live entirely
# inside the WSL distro. Afterwards open a new terminal (or run
# `wsl --shutdown` from Windows) so the docker group applies.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "error: run this script as root (sudo bash $0 [user])" >&2
    exit 1
fi

if ! grep -qi microsoft /proc/version; then
    echo "error: this does not look like WSL" >&2
    exit 1
fi

if [ ! -d /run/systemd/system ]; then
    echo "error: systemd is not running in this distro." >&2
    echo "Add '[boot]\\nsystemd=true' to /etc/wsl.conf, run 'wsl --shutdown' on Windows, and retry." >&2
    exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-}}"
if [ -z "$TARGET_USER" ] || ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "usage: sudo bash $0 <linux-user>" >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update -qq
apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

usermod -aG docker "$TARGET_USER"

systemctl enable --now docker

echo
echo "Docker installed:"
docker version --format '  engine {{.Server.Version}}'
docker compose version | sed 's/^/  /'
echo
echo "User '$TARGET_USER' added to the docker group."
echo "Open a new terminal (or run 'wsl --shutdown' from Windows) before using docker without sudo."
