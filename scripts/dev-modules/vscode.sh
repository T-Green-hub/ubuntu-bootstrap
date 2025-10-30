#!/usr/bin/env bash
# Module: VS Code installation
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_vscode(){
  if command -v code >/dev/null 2>&1; then
    log "VS Code already installed."
    return 0
  fi
  log "Installing VS Code…"
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
    https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | $(need_sudo) tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    $(need_sudo) tee /etc/apt/sources.list.d/vscode.list
  apt_safe update -qq
  apt_safe install -y code
  log "VS Code installed."
}

# Uninstall/rollback stub
uninstall_vscode(){
  log "[UNINSTALL] VS Code uninstall not yet implemented."
  # Example: $(need_sudo) apt-get remove --purge -y code
  return 0
}
