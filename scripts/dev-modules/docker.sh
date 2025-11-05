#!/usr/bin/env bash
# Module: Docker installation
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh" 2>/dev/null || true
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

# Check if Docker is installed
is_docker_installed() {
  command -v docker >/dev/null 2>&1 && return 0
  dpkg -l | grep -qE "docker-ce|containerd.io" 2>/dev/null && return 0
  return 1
}

# Backup Docker configuration before uninstall
# shellcheck disable=SC2120
backup_docker_config() {
  local backup_dir="${1:-$HOME/.config/bootstrap-backups/docker-$(date +%Y%m%d-%H%M%S)}"
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would create backup directory: $backup_dir"
  else
    mkdir -p "$backup_dir"
    log "Created backup directory: $backup_dir"
  fi
  
  # Backup Docker daemon configuration
  if [[ -f "/etc/docker/daemon.json" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would backup /etc/docker/daemon.json"
    else
      $(need_sudo) cp "/etc/docker/daemon.json" "$backup_dir/" 2>/dev/null || true
      $(need_sudo) chown "$USER:" "$backup_dir/daemon.json" 2>/dev/null || true
      log "Backed up daemon.json"
    fi
  fi
  
  # Save list of Docker images and containers (if Docker is running)
  if command -v docker >/dev/null 2>&1 && $(need_sudo) systemctl is-active docker.service >/dev/null 2>&1; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would backup Docker images and containers list"
    else
      $(need_sudo) docker images --format "{{.Repository}}:{{.Tag}}" > "$backup_dir/docker-images.txt" 2>/dev/null || true
      $(need_sudo) docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}" > "$backup_dir/docker-containers.txt" 2>/dev/null || true
      log "Backed up Docker images and containers list"
    fi
  fi
  
  echo "$backup_dir"
}

# Uninstall Docker
# shellcheck disable=SC2120
uninstall_docker() {
  log "Starting Docker uninstall..."
  
  if ! is_docker_installed; then
    log "Docker is not installed. Nothing to uninstall."
    return 0
  fi
  
  # User confirmation (skip in FORCE or DRY_RUN mode)
  if [[ "${FORCE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
    echo "⚠️  ⚠️  ⚠️  CRITICAL WARNING ⚠️  ⚠️  ⚠️"
    echo ""
    echo "This will remove:"
    echo "   - Docker Engine and all components"
    echo "   - All Docker containers (STOPPED AND RUNNING)"
    echo "   - All Docker images"
    echo "   - All Docker volumes"
    echo "   - All Docker networks"
    echo "   - Docker configuration files"
    echo "   - Your user from the docker group"
    echo ""
    echo "⚠️  DATA LOSS WARNING:"
    if [[ -d "/var/lib/docker" ]]; then
      local docker_size
      docker_size=$(du -sh /var/lib/docker 2>/dev/null | cut -f1 || echo "unknown")
      echo "   /var/lib/docker exists (size: $docker_size)"
      echo "   This contains ALL your Docker data!"
    fi
    echo ""
    echo "📋  A backup list of images/containers will be saved to:"
    echo "   ~/.config/bootstrap-backups/docker-YYYYMMDD-HHMMSS/"
    echo ""
    read -rp "Are you ABSOLUTELY SURE you want to continue? [type 'yes' to confirm] " confirm
    if [[ "$confirm" != "yes" ]]; then
      log "Docker uninstall cancelled by user."
      return 1
    fi
  fi
  
  # Create backup before uninstall
  local backup_dir
  backup_dir=$(backup_docker_config)
  log "Backup location: $backup_dir"
  
  # Stop Docker services
  if systemctl list-units --full -all | grep -qF "docker.service"; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would stop docker.service"
    else
      log "Stopping docker.service..."
      $(need_sudo) systemctl stop docker.service 2>/dev/null || true
      log "✓ Stopped docker.service"
    fi
  fi
  
  if systemctl list-units --full -all | grep -qF "docker.socket"; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would stop docker.socket"
    else
      log "Stopping docker.socket..."
      $(need_sudo) systemctl stop docker.socket 2>/dev/null || true
      log "✓ Stopped docker.socket"
    fi
  fi
  
  if systemctl list-units --full -all | grep -qF "containerd.service"; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would stop containerd.service"
    else
      log "Stopping containerd.service..."
      $(need_sudo) systemctl stop containerd.service 2>/dev/null || true
      log "✓ Stopped containerd.service"
    fi
  fi
  
  # Remove user from docker group
  if groups "$USER" | grep -q docker; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove $USER from docker group"
    else
      log "Removing $USER from docker group..."
      $(need_sudo) gpasswd -d "$USER" docker 2>/dev/null || true
      log "✓ Removed from docker group (logout required to take effect)"
    fi
  fi
  
  # Remove Docker packages
  local packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
    "docker-ce-rootless-extras"
  )
  
  local installed_packages=()
  for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
      installed_packages+=("$pkg")
    fi
  done
  
  if [[ ${#installed_packages[@]} -gt 0 ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove packages: ${installed_packages[*]}"
    else
      log "Removing Docker packages: ${installed_packages[*]}..."
      # shellcheck disable=SC2046
      $(need_sudo) apt-get remove --purge -y "${installed_packages[@]}" 2>/dev/null || true
      log "✓ Removed Docker packages"
    fi
  fi
  
  # Remove Docker APT repository
  if [[ -f "/etc/apt/sources.list.d/docker.list" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove /etc/apt/sources.list.d/docker.list"
    else
      log "Removing Docker APT repository..."
      $(need_sudo) rm -f "/etc/apt/sources.list.d/docker.list"
      log "✓ Removed Docker APT repository"
    fi
  fi
  
  # Remove Docker GPG key
  if [[ -f "/etc/apt/keyrings/docker.gpg" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove /etc/apt/keyrings/docker.gpg"
    else
      log "Removing Docker GPG key..."
      $(need_sudo) rm -f "/etc/apt/keyrings/docker.gpg"
      log "✓ Removed Docker GPG key"
    fi
  fi
  
  # Handle /var/lib/docker directory
  if [[ -d "/var/lib/docker" ]]; then
    if [[ "${FORCE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
      echo ""
      echo "⚠️  FINAL CONFIRMATION:"
      echo "   /var/lib/docker directory exists"
      echo "   This contains ALL your Docker data:"
      echo "   - Container filesystems"
      echo "   - Image layers"
      echo "   - Volumes"
      echo "   - Network configurations"
      echo ""
      local docker_size
      docker_size=$(du -sh /var/lib/docker 2>/dev/null | cut -f1 || echo "unknown")
      echo "   Total size: $docker_size"
      echo ""
      read -rp "Remove /var/lib/docker directory? [type 'DELETE' to confirm] " confirm_data
      if [[ "$confirm_data" == "DELETE" ]]; then
        log "Removing /var/lib/docker..."
        $(need_sudo) rm -rf "/var/lib/docker"
        log "✓ Removed /var/lib/docker"
      else
        log "Preserving /var/lib/docker (you can manually remove it later)"
      fi
    elif [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would ask about removing /var/lib/docker"
    elif [[ "${FORCE:-0}" == "1" ]]; then
      log "FORCE mode: Removing /var/lib/docker..."
      $(need_sudo) rm -rf "/var/lib/docker"
      log "✓ Removed /var/lib/docker"
    fi
  fi
  
  # Remove other Docker directories
  local docker_dirs=(
    "/var/lib/containerd"
    "/etc/docker"
    "/var/run/docker.sock"
  )
  
  for dir in "${docker_dirs[@]}"; do
    if [[ -e "$dir" ]]; then
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove: $dir"
      else
        log "Removing $dir..."
        $(need_sudo) rm -rf "$dir" 2>/dev/null || true
        log "✓ Removed $dir"
      fi
    fi
  done
  
  # Clean up APT cache
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    log "Cleaning APT cache..."
    $(need_sudo) apt-get autoremove -y 2>/dev/null || true
    $(need_sudo) apt-get autoclean 2>/dev/null || true
  fi
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Docker uninstall simulation complete"
  else
    log "✓ Docker uninstall complete"
    log "⚠️  IMPORTANT:"
    log "   - You have been removed from the docker group"
    log "   - Log out and back in for group changes to take effect"
    log "   - Backup saved to: $backup_dir"
  fi
  
  return 0
}

# Uninstall/rollback stub (keeping old name for backward compatibility)
uninstall_docker_old(){
  log "[UNINSTALL] Docker uninstall not yet implemented."
  # Example: $(need_sudo) apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Remove docker group, keyrings, sources, etc.
  return 0
}
