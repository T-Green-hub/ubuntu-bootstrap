#!/usr/bin/env bash
# Module: Python via pyenv
set -euo pipefail
IFS=$'\n\t'

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_python(){
  if command -v pyenv >/dev/null 2>&1; then
    log "✓ pyenv already installed: $(pyenv --version)"
    return 0
  fi
  
  log "Installing pyenv dependencies…"
  if apt_safe install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev; then
    log "✓ pyenv dependencies installed"
  else
    log "ERROR: Failed to install pyenv dependencies"
    return 1
  fi
  
  log "Installing pyenv…"
  local pyenv_installer
  pyenv_installer=$(mktemp) || {
    log "ERROR: Failed to create temporary file for pyenv installer"
    return 1
  }
  
  if ! curl --retry 3 --retry-delay 2 --connect-timeout 10 \
       -o "$pyenv_installer" https://pyenv.run; then
    log "ERROR: Failed to download pyenv installer"
    rm -f "$pyenv_installer"
    return 1
  fi
  
  # Security check: Verify it's a shell script
  if ! head -1 "$pyenv_installer" | grep -q "^#!/.*sh"; then
    log "ERROR: Downloaded pyenv installer is not a valid shell script"
    rm -f "$pyenv_installer"
    return 1
  fi
  
  # Additional security: Check file size is reasonable (not empty, not suspiciously large)
  local file_size
  file_size=$(stat -f%z "$pyenv_installer" 2>/dev/null || stat -c%s "$pyenv_installer" 2>/dev/null || echo 0)
  if [[ "$file_size" -lt 100 ]] || [[ "$file_size" -gt 1000000 ]]; then
    log "ERROR: Installer file size ($file_size bytes) is suspicious"
    rm -f "$pyenv_installer"
    return 1
  fi
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would execute pyenv installer"
  else
    if bash "$pyenv_installer"; then
      log "✓ pyenv installed successfully"
    else
      log "ERROR: pyenv installation failed"
      rm -f "$pyenv_installer"
      return 1
    fi
  fi
  rm -f "$pyenv_installer"
  
  local profile="$HOME/.bashrc"
  if ! grep -q 'pyenv init' "$profile" 2>/dev/null; then
    log "Adding pyenv to $profile…"
    if cat >> "$profile" <<'EOF'
# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
    then
      log "✓ pyenv configuration added to $profile"
    else
      log "WARNING: Failed to add pyenv configuration to $profile"
    fi
  else
    log "✓ pyenv already configured in $profile"
  fi
  
  log "✓ pyenv installed. Run 'pyenv install 3.12' to install Python 3.12"
}

# Uninstall/rollback stub
uninstall_python(){
  log "[UNINSTALL] pyenv uninstall not yet implemented."
  # Example: rm -rf "$HOME/.pyenv"
  return 0
}
