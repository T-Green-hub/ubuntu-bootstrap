#!/usr/bin/env bash
# Module: Rust via rustup
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_rust(){
  if command -v rustc >/dev/null 2>&1; then
    log "Rust already installed: $(rustc --version)"
    return 0
  fi
  log "Installing Rust via rustup…"
  local rustup_installer
  rustup_installer=$(mktemp) || {
    log "ERROR: Failed to create temporary file for rustup installer"
    return 1
  }
  curl --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 --connect-timeout 10 \
    -sSf -o "$rustup_installer" https://sh.rustup.rs || {
    log "ERROR: Failed to download rustup installer"
    rm -f "$rustup_installer"
    return 1
  }
  if ! head -1 "$rustup_installer" | grep -q "^#!/.*sh"; then
    log "ERROR: Downloaded rustup installer is not a shell script"
    rm -f "$rustup_installer"
    return 1
  fi
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would execute rustup installer"
  else
    sh "$rustup_installer" -y
  fi
  rm -f "$rustup_installer"
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
    log "Rust installed: $(rustc --version)"
  fi
}

# Uninstall/rollback stub
uninstall_rust(){
  log "[UNINSTALL] Rust uninstall not yet implemented."
  # Example: rm -rf "$HOME/.cargo" "$HOME/.rustup"
  return 0
}
