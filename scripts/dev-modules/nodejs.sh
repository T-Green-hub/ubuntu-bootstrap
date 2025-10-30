#!/usr/bin/env bash
# Module: Node.js via nvm
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_nodejs(){
  local NVM_DIR="$HOME/.nvm"
  if [[ -d "$NVM_DIR" ]]; then
    log "nvm already installed at $NVM_DIR"
  else
    log "Installing nvm (Node Version Manager)…"
    local nvm_installer
    nvm_installer=$(mktemp) || {
      log "ERROR: Failed to create temporary file for nvm installer"
      return 1
    }
    if curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
         -o "$nvm_installer" https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh; then
      bash "$nvm_installer"
      rm -f "$nvm_installer"
    else
      log "ERROR: Failed to download nvm installer"
      rm -f "$nvm_installer"
      return 1
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    set +u
    \. "$NVM_DIR/nvm.sh"
    if ! command -v node >/dev/null 2>&1; then
      log "Installing Node.js LTS…"
      nvm install --lts
      nvm use --lts
      log "Node.js installed: $(node --version)"
    else
      log "Node.js already installed: $(node --version)"
    fi
    set -u
  fi
}

# Uninstall/rollback stub
uninstall_nodejs(){
  log "[UNINSTALL] Node.js/nvm uninstall not yet implemented."
  # Example: rm -rf "$HOME/.nvm"
  return 0
}
