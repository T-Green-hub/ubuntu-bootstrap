#!/usr/bin/env bash
# Module: Docker installation
set -euo pipefail
IFS=$'\n\t'

source "${BASH_SOURCE%/*}/../../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

install_docker(){
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return 0
  fi

  log "Installing Docker…"
  apt_safe update -qq
  apt_safe install -y ca-certificates curl gnupg
  $(need_sudo) install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
      https://download.docker.com/linux/ubuntu/gpg | \
      $(need_sudo) gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $(need_sudo) chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    $(need_sudo) tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt_safe update -qq
  apt_safe install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  if ! command -v docker >/dev/null 2>&1; then
    log "ERROR: Docker installation verification failed"
    return 1
  fi
  if ! groups "$USER" | grep -q docker; then
    log "Adding $USER to docker group…"
    $(need_sudo) usermod -aG docker "$USER"
    log "Docker group added. Log out and back in for changes to take effect."
  fi
  log "Docker installed successfully."
}

# Uninstall/rollback stub
uninstall_docker(){
  log "[UNINSTALL] Docker uninstall not yet implemented."
  # Example: $(need_sudo) apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Remove docker group, keyrings, sources, etc.
  return 0
}
