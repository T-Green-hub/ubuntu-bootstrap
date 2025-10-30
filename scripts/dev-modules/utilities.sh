#!/usr/bin/env bash
# Module: Additional development utilities
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_dev_utilities(){
  local pkgs=(
    jq
    tree
    httpie
    ripgrep
    fd-find
    tmux
    sqlite3
  )
  local to_install=()
  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done
  if ((${#to_install[@]})); then
    log "Installing development utilities: ${to_install[*]}"
    apt_safe install -y "${to_install[@]}"
  else
    log "Development utilities already installed."
  fi
}

# Uninstall/rollback stub
uninstall_dev_utilities(){
  log "[UNINSTALL] Dev utilities uninstall not yet implemented."
  # Example: apt_safe remove -y jq tree httpie ripgrep fd-find tmux sqlite3
  return 0
}
