#!/usr/bin/env bash
# Module: VS Code installation
set -euo pipefail
IFS=$'\n\t'

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../lib/common.sh" ]]; then
  source "${SCRIPT_DIR}/../lib/common.sh"
else
  # Fallback definitions if common.sh not available
  log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
  need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }
fi

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

# Check if VS Code is installed
is_vscode_installed(){
  command -v code >/dev/null 2>&1 || dpkg -s code >/dev/null 2>&1
}

# Backup VS Code configuration
backup_vscode_config(){
  local backup_dir="${1:-$(create_backup_dir vscode)}"
  
  mkdir -p "$backup_dir"
  
  # Backup user settings if they exist
  if [[ -f "$HOME/.config/Code/User/settings.json" ]]; then
    mkdir -p "$backup_dir/Code/User"
    cp "$HOME/.config/Code/User/settings.json" "$backup_dir/Code/User/"
    log "[BACKUP] Saved VS Code settings"
  fi
  
  if [[ -f "$HOME/.config/Code/User/keybindings.json" ]]; then
    mkdir -p "$backup_dir/Code/User"
    cp "$HOME/.config/Code/User/keybindings.json" "$backup_dir/Code/User/"
    log "[BACKUP] Saved VS Code keybindings"
  fi
  
  # Backup extensions list
  if command -v code >/dev/null 2>&1; then
    code --list-extensions > "$backup_dir/extensions.list" 2>/dev/null || true
    log "[BACKUP] Saved VS Code extensions list"
  fi
  
  log "[BACKUP] Config backup directory: $backup_dir"
  echo "$backup_dir"
}

# Uninstall VS Code
uninstall_vscode(){
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting VS Code uninstall..."
  
  # Check if installed
  if ! is_vscode_installed; then
    log "[UNINSTALL] VS Code not installed, skipping."
    return 0
  fi
  
  # Confirm with user
  if ! confirm_action "This will remove VS Code and its repository configuration." "N"; then
    log "[UNINSTALL] Cancelled by user."
    return 0
  fi
  
  # Ask about user data
  local remove_user_data=0
  if [[ -d "$HOME/.config/Code" ]] || [[ -d "$HOME/.vscode" ]]; then
    echo ""
    echo "VS Code user data found:"
    [[ -d "$HOME/.config/Code" ]] && echo "  - ~/.config/Code (settings, extensions)"
    [[ -d "$HOME/.vscode" ]] && echo "  - ~/.vscode (workspace data)"
    echo ""
    
    if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
      read -p "Remove user data directories? [y/N] " -n 1 -r
      echo ""
      [[ $REPLY =~ ^[Yy]$ ]] && remove_user_data=1
    fi
  fi
  
  # Backup configs
  local backup_dir
  if [[ $dry_run -eq 0 ]]; then
    backup_dir=$(backup_vscode_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove VS Code package
  if dpkg -s code >/dev/null 2>&1; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove package: code"
    else
      log "[UNINSTALL] Removing VS Code package..."
      apt_safe remove -y code || log "WARNING: Package removal had issues"
    fi
  else
    log "[UNINSTALL] VS Code package not found."
  fi
  
  # Remove repository configuration
  if [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove /etc/apt/sources.list.d/vscode.list"
    else
      log "[UNINSTALL] Removing VS Code repository..."
      $(need_sudo) rm -f /etc/apt/sources.list.d/vscode.list
    fi
  fi
  
  # Remove GPG key
  if [[ -f /usr/share/keyrings/packages.microsoft.gpg ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove /usr/share/keyrings/packages.microsoft.gpg"
    else
      log "[UNINSTALL] Removing Microsoft GPG key..."
      $(need_sudo) rm -f /usr/share/keyrings/packages.microsoft.gpg
    fi
  fi
  
  # Update apt cache if we removed repo
  if [[ $dry_run -eq 0 ]] && [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    log "[UNINSTALL] Updating apt cache..."
    $(need_sudo) apt-get update -qq 2>/dev/null || true
  fi
  
  # Remove user data if requested
  if [[ $remove_user_data -eq 1 ]] && [[ $dry_run -eq 0 ]]; then
    log "[UNINSTALL] Removing user data..."
    rm -rf "$HOME/.config/Code"
    rm -rf "$HOME/.vscode"
    log "[UNINSTALL] User data removed."
  elif [[ $dry_run -eq 1 ]] && [[ $remove_user_data -eq 1 ]]; then
    log "[DRY_RUN] Would remove ~/.config/Code and ~/.vscode"
  fi
  
  # Cleanup
  if [[ $dry_run -eq 0 ]]; then
    log "[UNINSTALL] Running apt autoremove..."
    apt_safe autoremove -y || true
  else
    log "[DRY_RUN] Would run apt autoremove"
  fi
  
  log "[UNINSTALL] VS Code uninstall complete."
  return 0
}
