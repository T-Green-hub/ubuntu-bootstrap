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

# Check if dev utilities are installed
is_dev_utilities_installed(){
  local pkgs=(jq tree httpie ripgrep fd-find tmux sqlite3)
  for pkg in "${pkgs[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      return 0  # At least one package is installed
    fi
  done
  return 1  # None installed
}

# Backup dev utilities configuration (placeholder for future use)
backup_dev_utilities_config(){
  local backup_dir="${1:-$HOME/.local/share/ubuntu-bootstrap/backups/dev-utilities-$(date +%Y%m%d-%H%M%S)}"
  
  # Create backup directory
  mkdir -p "$backup_dir"
  
  # Currently no configs to backup for these utilities
  # This is a placeholder for future expansion
  log "[BACKUP] Config backup directory: $backup_dir"
  echo "$backup_dir"
}

# Uninstall/rollback implementation
uninstall_dev_utilities(){
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting dev utilities uninstall..."
  
  # Check if installed
  if ! is_dev_utilities_installed; then
    log "[UNINSTALL] Dev utilities not installed, skipping."
    return 0
  fi
  
  # Confirm with user (unless FORCE=1 or DRY_RUN=1)
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    echo ""
    echo "This will remove the following packages:"
    echo "  - jq, tree, httpie, ripgrep, fd-find, tmux, sqlite3"
    echo ""
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "[UNINSTALL] Cancelled by user."
      return 0
    fi
  fi
  
  # Backup configs (even though minimal for these tools)
  local backup_dir
  if [[ $dry_run -eq 0 ]]; then
    backup_dir=$(backup_dev_utilities_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove packages
  local pkgs=(jq tree httpie ripgrep fd-find tmux sqlite3)
  local to_remove=()
  
  for pkg in "${pkgs[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      to_remove+=("$pkg")
    fi
  done
  
  if ((${#to_remove[@]})); then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove packages: ${to_remove[*]}"
    else
      log "[UNINSTALL] Removing packages: ${to_remove[*]}"
      apt_safe remove -y "${to_remove[@]}"
      log "[UNINSTALL] Packages removed successfully."
    fi
  else
    log "[UNINSTALL] No packages to remove."
  fi
  
  # Cleanup and verification
  if [[ $dry_run -eq 0 ]]; then
    log "[UNINSTALL] Running apt autoremove..."
    apt_safe autoremove -y
  else
    log "[DRY_RUN] Would run apt autoremove"
  fi
  
  log "[UNINSTALL] Dev utilities uninstall complete."
  return 0
}
