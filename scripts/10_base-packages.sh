#!/usr/bin/env bash
# Ubuntu 24.04 base packages with safe APT settings (idempotent).

set -euo pipefail
IFS=$'\n\t'

REQUIRED_PKGS=( curl git vim build-essential htop lm-sensors smartmontools nvme-cli psmisc )

APT_NET_CONF="/etc/apt/apt.conf.d/98-bootstrap-net"
APT_NET_BODY=$(cat <<'EOT'
Acquire::ForceIPv4 "true";
Acquire::Retries "5";
Acquire::http::Timeout "20";
Acquire::https::Timeout "20";
APT::Get::Assume-Yes "true";
APT::Color "0";
Dpkg::Progress-Fancy "0";
EOT
)

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

ensure_apt_conf(){
  if [[ ! -f "$APT_NET_CONF" ]]; then
    log "Adding APT net/retry conf → $APT_NET_CONF"
    if printf '%s\n' "$APT_NET_BODY" | $(need_sudo) tee "$APT_NET_CONF" >/dev/null; then
      log "✓ APT configuration created successfully"
    else
      log "ERROR: Failed to create APT configuration"
      return 1
    fi
  else
    log "✓ APT conf already present: $APT_NET_CONF"
  fi
}

apt_refresh(){ 
  log "Running apt update (IPv4, with retries)…"
  if $(need_sudo) apt-get update -o Acquire::ForceIPv4=true -o Acquire::Retries=5; then
    log "✓ Package lists updated successfully"
  else
    log "ERROR: apt update failed"
    return 1
  fi
}

install_pkgs(){
  local to_install=()
  for p in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
      to_install+=("$p")
    fi
  done
  if ((${#to_install[@]})); then
    log "Installing ${#to_install[@]} packages: ${to_install[*]}"
    if $(need_sudo) apt-get install -y "${to_install[@]}"; then
      log "✓ All packages installed successfully"
    else
      log "ERROR: Package installation failed"
      return 1
    fi
  else
    log "✓ All required packages already installed"
  fi
}

main(){ ensure_apt_conf; apt_refresh; install_pkgs; log "Base package setup complete."; }
main "$@"
