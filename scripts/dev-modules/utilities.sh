#!/usr/bin/env bash
# Module: Additional development utilities
# Installs common CLI utilities for development work
set -euo pipefail
IFS=$'\n\t'

# Source common library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../lib/common.sh" 2>/dev/null || true

# Fallback log function if common.sh not loaded
if ! declare -f log >/dev/null 2>&1; then
  log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
fi

# Fallback need_sudo function if common.sh not loaded
if ! declare -f need_sudo >/dev/null 2>&1; then
  need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }
fi

# Fallback apt_safe if not available
if ! declare -f apt_safe >/dev/null 2>&1; then
  apt_safe() {
    local cmd="$1"
    shift
    $(need_sudo) apt-get "$cmd" "$@"
  }
fi

# List of utilities to install
get_utility_packages() {
  echo "jq"          # JSON processor
  echo "tree"        # Directory tree viewer
  echo "httpie"      # User-friendly HTTP client
  echo "ripgrep"     # Fast grep alternative (rg)
  echo "fd-find"     # Fast find alternative (fd/fdfind)
  echo "tmux"        # Terminal multiplexer
  echo "sqlite3"     # SQLite database CLI
  echo "bat"         # Better cat with syntax highlighting
  echo "ncdu"        # NCurses disk usage analyzer
}

# Display utility versions
show_utility_versions() {
  log "Installed utility versions:"
  
  command -v jq >/dev/null 2>&1 && \
    log "  - jq: $(jq --version 2>&1)"
  
  command -v tree >/dev/null 2>&1 && \
    log "  - tree: $(tree --version 2>&1 | head -n1)"
  
  command -v http >/dev/null 2>&1 && \
    log "  - httpie: $(http --version 2>&1 | head -n1)"
  
  command -v rg >/dev/null 2>&1 && \
    log "  - ripgrep: $(rg --version 2>&1 | head -n1)"
  
  command -v fdfind >/dev/null 2>&1 && \
    log "  - fd-find: $(fdfind --version 2>&1)"
  
  command -v tmux >/dev/null 2>&1 && \
    log "  - tmux: $(tmux -V 2>&1)"
  
  command -v sqlite3 >/dev/null 2>&1 && \
    log "  - sqlite3: $(sqlite3 --version 2>&1)"
  
  command -v bat >/dev/null 2>&1 && \
    log "  - bat: $(bat --version 2>&1 | head -n1)"
  
  command -v ncdu >/dev/null 2>&1 && \
    log "  - ncdu: $(ncdu --version 2>&1 | head -n1)"
}

# Setup symbolic links and configurations
setup_utility_links() {
  # Create fd symlink if fdfind exists but fd doesn't
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    if [[ -L "$bin_dir/fd" ]] || [[ ! -e "$bin_dir/fd" ]]; then
      ln -sf "$(command -v fdfind)" "$bin_dir/fd"
      log "Created symlink: fd -> fdfind"
      
      # Add to PATH if not already there
      if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        log "Note: Add $bin_dir to your PATH to use 'fd' command"
      fi
    fi
  fi
  
  # Create batcat symlink if bat exists but batcat doesn't (Ubuntu packages bat as batcat)
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    if [[ -L "$bin_dir/bat" ]] || [[ ! -e "$bin_dir/bat" ]]; then
      ln -sf "$(command -v batcat)" "$bin_dir/bat"
      log "Created symlink: bat -> batcat"
    fi
  fi
}

# Main installation function
install_dev_utilities() {
  # Check if already installed
  local all_installed=true
  local pkgs=()
  
  while IFS= read -r pkg; do
    pkgs+=("$pkg")
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      all_installed=false
    fi
  done < <(get_utility_packages)
  
  if $all_installed; then
    log "All development utilities are already installed."
    show_utility_versions
    setup_utility_links
    return 0
  fi
  
  # Determine which packages need installation
  local to_install=()
  for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done
  
  if ((${#to_install[@]} == 0)); then
    log "All development utilities are already installed."
    show_utility_versions
    setup_utility_links
    return 0
  fi
  
  log "Installing development utilities: ${to_install[*]}"
  
  # Update package lists
  log "Updating package lists..."
  apt_safe update -qq || {
    log "WARNING: apt update failed, continuing anyway..."
  }
  
  # Install packages
  if apt_safe install -y "${to_install[@]}"; then
    log "✓ Development utilities installed successfully"
  else
    log "ERROR: Failed to install some utilities"
    return 1
  fi
  
  # Verify installation
  local failed=()
  for pkg in "${to_install[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      failed+=("$pkg")
    fi
  done
  
  if ((${#failed[@]} > 0)); then
    log "ERROR: Failed to install: ${failed[*]}"
    return 1
  fi
  
  # Setup symbolic links
  setup_utility_links
  
  # Show installed versions
  show_utility_versions
  
  log "✓ All development utilities ready to use"
  return 0
}

# Check if dev utilities are installed
is_dev_utilities_installed() {
  local pkgs=()
  while IFS= read -r pkg; do
    pkgs+=("$pkg")
  done < <(get_utility_packages)
  
  for pkg in "${pkgs[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      return 0  # At least one package is installed
    fi
  done
  return 1  # None installed
}

# Get list of installed utilities
get_installed_utilities() {
  local installed=()
  local pkgs=()
  
  while IFS= read -r pkg; do
    pkgs+=("$pkg")
  done < <(get_utility_packages)
  
  for pkg in "${pkgs[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      installed+=("$pkg")
    fi
  done
  
  printf '%s\n' "${installed[@]}"
}

# Backup dev utilities configuration
backup_dev_utilities_config() {
  local backup_dir="${1:-$HOME/.local/share/ubuntu-bootstrap/backups/dev-utilities-$(date +%Y%m%d-%H%M%S)}"
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY_RUN] Would create backup directory: $backup_dir"
    echo "$backup_dir"
    return 0
  fi
  
  # Create backup directory
  mkdir -p "$backup_dir"
  log "[BACKUP] Created backup directory: $backup_dir"
  
  # Backup tmux configuration
  if [[ -f "$HOME/.tmux.conf" ]]; then
    cp "$HOME/.tmux.conf" "$backup_dir/tmux.conf"
    log "[BACKUP] Saved ~/.tmux.conf"
  fi
  
  # Backup ripgrep configuration
  if [[ -f "$HOME/.ripgreprc" ]]; then
    cp "$HOME/.ripgreprc" "$backup_dir/ripgreprc"
    log "[BACKUP] Saved ~/.ripgreprc"
  fi
  
  # Backup bat configuration
  if [[ -d "$HOME/.config/bat" ]]; then
    cp -r "$HOME/.config/bat" "$backup_dir/"
    log "[BACKUP] Saved ~/.config/bat/"
  fi
  
  # Backup sqlite history
  if [[ -f "$HOME/.sqlite_history" ]]; then
    cp "$HOME/.sqlite_history" "$backup_dir/sqlite_history"
    log "[BACKUP] Saved ~/.sqlite_history"
  fi
  
  # Backup httpie config
  if [[ -d "$HOME/.config/httpie" ]]; then
    cp -r "$HOME/.config/httpie" "$backup_dir/"
    log "[BACKUP] Saved ~/.config/httpie/"
  fi
  
  # Create a list of installed utilities
  get_installed_utilities > "$backup_dir/installed_packages.txt"
  log "[BACKUP] Saved list of installed packages"
  
  echo "$backup_dir"
}

# Uninstall/rollback implementation
uninstall_dev_utilities() {
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting dev utilities uninstall..."
  
  # Check if installed
  if ! is_dev_utilities_installed; then
    log "[UNINSTALL] Dev utilities not installed, skipping."
    return 0
  fi
  
  # Get list of installed packages
  local installed=()
  while IFS= read -r pkg; do
    installed+=("$pkg")
  done < <(get_installed_utilities)
  
  if ((${#installed[@]} == 0)); then
    log "[UNINSTALL] No dev utilities found to uninstall."
    return 0
  fi
  
  # Confirm with user (unless FORCE=1 or DRY_RUN=1)
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    echo ""
    echo "⚠️  This will remove the following packages:"
    printf '   - %s\n' "${installed[@]}"
    echo ""
    echo "Configuration files will be backed up to:"
    echo "   ~/.local/share/ubuntu-bootstrap/backups/dev-utilities-*/"
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
    backup_dir=$(backup_dev_utilities_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove symbolic links
  if [[ $dry_run -eq 1 ]]; then
    log "[DRY_RUN] Would remove symbolic links (fd, bat)"
  else
    if [[ -L "$HOME/.local/bin/fd" ]]; then
      rm -f "$HOME/.local/bin/fd"
      log "[CLEANUP] Removed symlink: ~/.local/bin/fd"
    fi
    if [[ -L "$HOME/.local/bin/bat" ]]; then
      rm -f "$HOME/.local/bin/bat"
      log "[CLEANUP] Removed symlink: ~/.local/bin/bat"
    fi
  fi
  
  # Remove packages
  local pkgs=()
  while IFS= read -r pkg; do
    pkgs+=("$pkg")
  done < <(get_utility_packages)
  
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
      if apt_safe remove -y "${to_remove[@]}"; then
        log "✓ Packages removed successfully"
      else
        log "ERROR: Failed to remove some packages"
        return 1
      fi
    fi
  else
    log "[UNINSTALL] No packages to remove."
  fi
  
  # Cleanup and verification
  if [[ $dry_run -eq 0 ]]; then
    log "[CLEANUP] Running apt autoremove..."
    apt_safe autoremove -y || log "WARNING: apt autoremove had issues"
  else
    log "[DRY_RUN] Would run apt autoremove"
  fi
  
  # Final verification
  if [[ $dry_run -eq 0 ]]; then
    local still_installed=()
    for pkg in "${to_remove[@]}"; do
      if dpkg -s "$pkg" >/dev/null 2>&1; then
        still_installed+=("$pkg")
      fi
    done
    
    if ((${#still_installed[@]} > 0)); then
      log "WARNING: Some packages still installed: ${still_installed[*]}"
      return 1
    fi
  fi
  
  if [[ $dry_run -eq 1 ]]; then
    log "[DRY_RUN] Dev utilities uninstall simulation complete"
  else
    log "✓ Dev utilities uninstall complete"
    log "   Backup location: $backup_dir"
  fi
  
  return 0
}
