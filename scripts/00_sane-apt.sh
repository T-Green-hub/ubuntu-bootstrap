#!/usr/bin/env bash
# Ubuntu 24.04 APT configuration and repository setup (idempotent).
# Ensures proper repositories, fastest mirrors, and performance tuning.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# Ensure all standard repos are enabled
ensure_repositories(){
  log "Ensuring universe and multiverse repositories…"
  
  # Check if repos already enabled
  if grep -qE '^deb.*universe' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    log "✓ Universe repository already enabled"
  else
    log "Adding universe repository…"
    if $(need_sudo) add-apt-repository -y universe; then
      log "✓ Universe repository added"
    else
      log "ERROR: Failed to add universe repository"
      return 1
    fi
  fi
  
  if grep -qE '^deb.*multiverse' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    log "✓ Multiverse repository already enabled"
  else
    log "Adding multiverse repository…"
    if $(need_sudo) add-apt-repository -y multiverse; then
      log "✓ Multiverse repository added"
    else
      log "ERROR: Failed to add multiverse repository"
      return 1
    fi
  fi
}

# APT performance configuration
setup_apt_performance(){
  local conf_file="/etc/apt/apt.conf.d/99-bootstrap-performance"
  
  if [[ -f "$conf_file" ]]; then
    log "✓ APT performance config already exists: $conf_file"
    return 0
  fi
  
  log "Creating APT performance configuration → $conf_file"
  
  if cat <<'EOF' | $(need_sudo) tee "$conf_file" >/dev/null
# Bootstrap APT performance tuning
# Parallel downloads and connection optimization

# Download optimization
Acquire::Queue-Mode "host";
Acquire::http::Pipeline-Depth "5";
Binary::apt::APT::Keep-Downloaded-Packages "true";

# Keep package cache for reinstalls
APT::Keep-Downloaded-Packages "true";

# Faster dpkg
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF
  then
    log "✓ APT performance config created"
  else
    log "ERROR: Failed to create APT performance config"
    return 1
  fi
}

# Install essential repository management tools
install_repo_tools(){
  local tools=( software-properties-common apt-transport-https ca-certificates gnupg )
  local to_install=()
  
  for pkg in "${tools[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done
  
  if ((${#to_install[@]})); then
    log "Installing ${#to_install[@]} repository tools: ${to_install[*]}"
    apt_safe update -qq
    if apt_safe install -y "${to_install[@]}"; then
      log "✓ Repository tools installed successfully"
    else
      log "ERROR: Failed to install repository tools"
      return 1
    fi
  else
    log "✓ All repository tools already installed"
  fi
}

main(){
  log "=== APT Configuration & Repository Setup ==="
  install_repo_tools
  ensure_repositories
  setup_apt_performance
  log "APT setup complete."
}

main "$@"
