#!/usr/bin/env bash
# Module: Node.js via nvm
set -euo pipefail
IFS=$'\n\t'

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  source "${SCRIPT_DIR}/../lib/common.sh"
else
  # Fallback definitions
  log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
fi

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

# Check if Node.js/nvm is installed
is_nodejs_installed(){
  [[ -d "$HOME/.nvm" ]] || command -v node >/dev/null 2>&1
}

# Backup Node.js/nvm configuration
backup_nodejs_config(){
  local backup_dir="${1:-$(create_backup_dir nodejs)}"
  
  mkdir -p "$backup_dir"
  
  # Backup .npmrc if exists
  if [[ -f "$HOME/.npmrc" ]]; then
    cp "$HOME/.npmrc" "$backup_dir/"
    log "[BACKUP] Saved .npmrc"
  fi
  
  # Backup shell configs
  backup_shell_file "$HOME/.bashrc" "$backup_dir" 2>/dev/null || true
  backup_shell_file "$HOME/.profile" "$backup_dir" 2>/dev/null || true
  backup_shell_file "$HOME/.bash_profile" "$backup_dir" 2>/dev/null || true
  
  # List installed Node versions
  if [[ -d "$HOME/.nvm/versions/node" ]]; then
    ls "$HOME/.nvm/versions/node" > "$backup_dir/node_versions.list" 2>/dev/null || true
    log "[BACKUP] Saved Node versions list"
  fi
  
  # List global npm packages
  if command -v npm >/dev/null 2>&1; then
    npm list -g --depth=0 > "$backup_dir/global_packages.list" 2>/dev/null || true
    log "[BACKUP] Saved global npm packages list"
  fi
  
  log "[BACKUP] Config backup directory: $backup_dir"
  echo "$backup_dir"
}

# Uninstall Node.js/nvm
uninstall_nodejs(){
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting Node.js/nvm uninstall..."
  
  # Check if installed
  if ! is_nodejs_installed; then
    log "[UNINSTALL] Node.js/nvm not installed, skipping."
    return 0
  fi
  
  # Show what will be removed
  echo ""
  echo "This will remove:"
  echo "  - ~/.nvm directory (Node.js installations)"
  echo "  - nvm lines from shell config files (.bashrc, .profile)"
  [[ -d "$HOME/.npm" ]] && echo "  - ~/.npm cache directory"
  echo ""
  
  # Confirm with user
  if ! confirm_action "Proceed with Node.js/nvm uninstall?" "N"; then
    log "[UNINSTALL] Cancelled by user."
    return 0
  fi
  
  # Backup configs
  local backup_dir
  if [[ $dry_run -eq 0 ]]; then
    backup_dir=$(backup_nodejs_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove ~/.nvm directory
  if [[ -d "$HOME/.nvm" ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove ~/.nvm directory"
    else
      log "[UNINSTALL] Removing ~/.nvm directory..."
      rm -rf "$HOME/.nvm"
      log "[UNINSTALL] ~/.nvm removed."
    fi
  else
    log "[UNINSTALL] ~/.nvm directory not found."
  fi
  
  # Clean shell configuration files
  local shell_files=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")
  local nvm_patterns=(
    'export NVM_DIR="$HOME/.nvm"'
    'export NVM_DIR=$HOME/.nvm'
    '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
    '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
    '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'
  )
  
  for file in "${shell_files[@]}"; do
    if [[ -f "$file" ]]; then
      for pattern in "${nvm_patterns[@]}"; do
        if [[ $dry_run -eq 1 ]]; then
          if grep -qF "$pattern" "$file" 2>/dev/null; then
            log "[DRY_RUN] Would remove nvm line from $file"
          fi
        else
          remove_lines_from_file "$file" "$pattern" 2>/dev/null || true
        fi
      done
    fi
  done
  
  # Ask about ~/.npm cache
  if [[ -d "$HOME/.npm" ]]; then
    local remove_npm_cache=0
    if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
      echo ""
      read -p "Remove ~/.npm cache directory? [y/N] " -n 1 -r
      echo ""
      [[ $REPLY =~ ^[Yy]$ ]] && remove_npm_cache=1
    elif [[ $force -eq 1 ]]; then
      remove_npm_cache=1
    fi
    
    if [[ $remove_npm_cache -eq 1 ]]; then
      if [[ $dry_run -eq 1 ]]; then
        log "[DRY_RUN] Would remove ~/.npm directory"
      else
        log "[UNINSTALL] Removing ~/.npm cache..."
        rm -rf "$HOME/.npm"
      fi
    fi
  fi
  
  # Verify cleanup
  if [[ $dry_run -eq 0 ]]; then
    for file in "${shell_files[@]}"; do
      for pattern in "${nvm_patterns[@]}"; do
        verify_pattern_removed "$file" "$pattern" 2>/dev/null || true
      done
    done
  fi
  
  log "[UNINSTALL] Node.js/nvm uninstall complete."
  log "[NOTE] You may need to restart your shell or run: source ~/.bashrc"
  return 0
}
