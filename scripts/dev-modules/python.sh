#!/usr/bin/env bash
# Module: Python via pyenv
set -euo pipefail
IFS=$'\n\t'

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh disable=SC1091
source "$SCRIPT_DIR/../lib/common.sh"

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

# Detection function
is_python_installed() {
  if [[ -d "$HOME/.pyenv" ]]; then
    return 0
  fi
  return 1
}

# Backup function
# shellcheck disable=SC2120
backup_python_config() {
  local backup_dir="${1:-$(create_backup_dir "python")}"
  
  mkdir -p "$backup_dir"
  
  # Backup .python-version if exists
  if [[ -f "$HOME/.python-version" ]]; then
    cp "$HOME/.python-version" "$backup_dir/"
    log "[BACKUP] Saved .python-version"
  fi
  
  # List installed Python versions
  if [[ -d "$HOME/.pyenv/versions" ]]; then
    ls -1 "$HOME/.pyenv/versions" > "$backup_dir/installed_versions.txt" 2>/dev/null || true
    log "[BACKUP] Saved list of installed Python versions"
  fi
  
  # Backup shell configs
  backup_shell_file "$HOME/.bashrc" "$backup_dir"
  backup_shell_file "$HOME/.profile" "$backup_dir"
  
  log "[BACKUP] Backup created at: $backup_dir"
  echo "$backup_dir"
}

# Uninstall function
uninstall_python() {
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting Python (pyenv) uninstall..."
  
  # Check if installed
  if ! is_python_installed; then
    log "[UNINSTALL] Python (pyenv) not installed, skipping."
    return 0
  fi
  
  # Confirm with user
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    echo ""
    echo "This will remove:"
    echo "  - ~/.pyenv directory (all installed Python versions)"
    echo "  - Python virtual environments (if any)"
    echo "  - pyenv configuration from shell configs"
    echo ""
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "[UNINSTALL] Cancelled by user."
      return 0
    fi
  fi
  
  # Backup configs
  local backup_dir
  if [[ $dry_run -eq 0 ]]; then
    # shellcheck disable=SC2119
    backup_dir=$(backup_python_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove pyenv directory
  if [[ -d "$HOME/.pyenv" ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove directory: $HOME/.pyenv"
    else
      log "[UNINSTALL] Removing $HOME/.pyenv..."
      rm -rf "$HOME/.pyenv"
    fi
  fi
  
  # Remove .python-version file
  if [[ -f "$HOME/.python-version" ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove file: $HOME/.python-version"
    else
      log "[UNINSTALL] Removing $HOME/.python-version"
      rm -f "$HOME/.python-version"
    fi
  fi
  
  # Clean shell configs
  local shell_configs=("$HOME/.bashrc" "$HOME/.profile")
  local patterns=(
    "export PYENV_ROOT="
    "pyenv init"
    "# pyenv configuration"
  )
  
  for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
      for pattern in "${patterns[@]}"; do
        if grep -qF "$pattern" "$config" 2>/dev/null; then
          if [[ $dry_run -eq 1 ]]; then
            log "[DRY_RUN] Would remove pyenv lines from $config"
          else
            log "[UNINSTALL] Cleaning $config..."
            remove_lines_from_file "$config" "$pattern"
          fi
        fi
      done
    fi
  done
  
  log "[UNINSTALL] Python (pyenv) uninstall complete."
  log "Note: Restart your shell or run 'exec bash' to apply changes."
  return 0
}
