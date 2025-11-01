#!/usr/bin/env bash
# Module: Docker installation
set -euo pipefail
IFS=$'\n\t'

source "${BASH_SOURCE%/*}/../../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

install_docker(){
  if command -v docker >/dev/null 2>&1; then
    log "✓ Docker already installed: $(docker --version)"
    return 0
  fi

  log "Installing Docker…"
  
  # Install prerequisites
  apt_safe update -qq || return 1
  apt_safe install -y ca-certificates curl gnupg || return 1
  
  # Create keyrings directory
  if ! $(need_sudo) install -m 0755 -d /etc/apt/keyrings; then
    log "ERROR: Failed to create keyrings directory"
    return 1
  fi
  
  # Add Docker GPG key
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    log "Adding Docker GPG key…"
    if ! curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
         https://download.docker.com/linux/ubuntu/gpg | \
         $(need_sudo) gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
      log "ERROR: Failed to download Docker GPG key"
      return 1
    fi
    $(need_sudo) chmod a+r /etc/apt/keyrings/docker.gpg
    log "✓ Docker GPG key added"
  fi
  
  # Add Docker repository
  log "Adding Docker repository…"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    $(need_sudo) tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Install Docker packages
  apt_safe update -qq || return 1
  apt_safe install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || return 1
  
  # Verify installation
  if ! command -v docker >/dev/null 2>&1; then
    log "ERROR: Docker installation verification failed"
    return 1
  fi
  
  # Add user to docker group
  if ! groups "$USER" | grep -q docker; then
    log "Adding $USER to docker group…"
    if $(need_sudo) usermod -aG docker "$USER"; then
      log "✓ User added to docker group"
      log "⚠ You must log out and back in for group changes to take effect"
    else
      log "WARNING: Failed to add user to docker group"
    fi
  else
    log "✓ User already in docker group"
  fi
  
  log "✓ Docker installed successfully: $(docker --version)"
}

# Uninstall/rollback stub
uninstall_docker(){
  log "[UNINSTALL] Docker uninstall not yet implemented."
  # Example: $(need_sudo) apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Remove docker group, keyrings, sources, etc.
  return 0
}
