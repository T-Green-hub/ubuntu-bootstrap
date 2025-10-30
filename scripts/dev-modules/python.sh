#!/usr/bin/env bash
# Module: Python via pyenv
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_python(){
  if command -v pyenv >/dev/null 2>&1; then
    log "pyenv already installed: $(pyenv --version)"
    return 0
  fi
  log "Installing pyenv dependencies…"
  apt_safe install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
  log "Installing pyenv…"
  local pyenv_installer
  pyenv_installer=$(mktemp) || {
    log "ERROR: Failed to create temporary file for pyenv installer"
    return 1
  }
  curl --retry 3 --retry-delay 2 --connect-timeout 10 \
    -o "$pyenv_installer" https://pyenv.run || {
    log "ERROR: Failed to download pyenv installer"
    rm -f "$pyenv_installer"
    return 1
  }
  if ! head -1 "$pyenv_installer" | grep -q "^#!/.*sh"; then
    log "ERROR: Downloaded pyenv installer is not a shell script"
    rm -f "$pyenv_installer"
    return 1
  fi
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would execute pyenv installer"
  else
    bash "$pyenv_installer"
  fi
  rm -f "$pyenv_installer"
  local profile="$HOME/.bashrc"
  if ! grep -q 'pyenv init' "$profile" 2>/dev/null; then
    log "Adding pyenv to $profile…"
    cat >> "$profile" <<'EOF'
# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
  fi
  log "pyenv installed. Run 'pyenv install 3.12' to install Python 3.12."
}

# Uninstall/rollback stub
uninstall_python(){
  log "[UNINSTALL] pyenv uninstall not yet implemented."
  # Example: rm -rf "$HOME/.pyenv"
  return 0
}
