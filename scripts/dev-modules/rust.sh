#!/usr/bin/env bash
# Module: Rust via rustup
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh" 2>/dev/null || true

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

install_rust(){
  if command -v rustc >/dev/null 2>&1; then
    log "Rust already installed: $(rustc --version)"
    return 0
  fi
  log "Installing Rust via rustup…"
  local rustup_installer
  rustup_installer=$(mktemp) || {
    log "ERROR: Failed to create temporary file for rustup installer"
    return 1
  }
  curl --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 --connect-timeout 10 \
    -sSf -o "$rustup_installer" https://sh.rustup.rs || {
    log "ERROR: Failed to download rustup installer"
    rm -f "$rustup_installer"
    return 1
  }
  if ! head -1 "$rustup_installer" | grep -q "^#!/.*sh"; then
    log "ERROR: Downloaded rustup installer is not a shell script"
    rm -f "$rustup_installer"
    return 1
  fi
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would execute rustup installer"
  else
    sh "$rustup_installer" -y
  fi
  rm -f "$rustup_installer"
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
    log "Rust installed: $(rustc --version)"
  fi
}

# Check if Rust is installed
is_rust_installed() {
  [[ -d "$HOME/.cargo" || -d "$HOME/.rustup" ]] && return 0
  command -v rustc >/dev/null 2>&1 && return 0
  return 1
}

# Backup Rust configuration before uninstall
# shellcheck disable=SC2120
backup_rust_config() {
  local backup_dir="${1:-$HOME/.config/bootstrap-backups/rust-$(date +%Y%m%d-%H%M%S)}"
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would create backup directory: $backup_dir"
  else
    mkdir -p "$backup_dir"
    log "Created backup directory: $backup_dir"
  fi
  
  # Backup rustup/cargo directories if they exist
  if [[ -d "$HOME/.rustup" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would backup ~/.rustup/settings.toml"
    else
      [[ -f "$HOME/.rustup/settings.toml" ]] && cp "$HOME/.rustup/settings.toml" "$backup_dir/"
      log "Backed up rustup settings"
    fi
  fi
  
  if [[ -d "$HOME/.cargo" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would backup ~/.cargo/config.toml"
    else
      [[ -f "$HOME/.cargo/config.toml" ]] && cp "$HOME/.cargo/config.toml" "$backup_dir/"
      log "Backed up cargo config"
    fi
  fi
  
  # Backup shell configurations
  for shell_file in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
    if [[ -f "$shell_file" ]] && grep -q "cargo\|rustup" "$shell_file" 2>/dev/null; then
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would backup $(basename "$shell_file")"
      else
        backup_shell_file "$shell_file" "$backup_dir"
      fi
    fi
  done
  
  echo "$backup_dir"
}

# Uninstall Rust and rustup
# shellcheck disable=SC2120
uninstall_rust() {
  log "Starting Rust uninstall..."
  
  if ! is_rust_installed; then
    log "Rust is not installed. Nothing to uninstall."
    return 0
  fi
  
  # User confirmation (skip in FORCE or DRY_RUN mode)
  if [[ "${FORCE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
    echo "⚠️  This will remove:"
    echo "   - Rustup toolchain manager (~/.rustup)"
    echo "   - Cargo and installed crates (~/.cargo)"
    echo "   - All Rust-related shell configuration"
    echo ""
    read -rp "Continue with Rust uninstall? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log "Rust uninstall cancelled by user."
      return 1
    fi
  fi
  
  # Create backup before uninstall
  local backup_dir
  backup_dir=$(backup_rust_config)
  log "Backup location: $backup_dir"
  
  # Use rustup self-uninstall if available
  if command -v rustup >/dev/null 2>&1; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would run: rustup self uninstall -y"
    else
      log "Running rustup self-uninstall..."
      rustup self uninstall -y 2>/dev/null || {
        log "WARNING: rustup self-uninstall failed, continuing with manual cleanup"
      }
    fi
  fi
  
  # Remove ~/.cargo directory
  if [[ -d "$HOME/.cargo" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove: ~/.cargo"
    else
      log "Removing ~/.cargo directory..."
      rm -rf "$HOME/.cargo"
      log "✓ Removed ~/.cargo"
    fi
  fi
  
  # Remove ~/.rustup directory (if rustup self-uninstall didn't handle it)
  if [[ -d "$HOME/.rustup" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove: ~/.rustup"
    else
      log "Removing ~/.rustup directory..."
      rm -rf "$HOME/.rustup"
      log "✓ Removed ~/.rustup"
    fi
  fi
  
  # Clean up shell configurations
  local shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc")
  for shell_file in "${shell_files[@]}"; do
    if [[ ! -f "$shell_file" ]]; then
      continue
    fi
    
    # Patterns to remove (cargo env sourcing)
    local patterns=(
      '.*\.cargo/env.*'
      'source.*cargo.*'
      '\. .*cargo.*'
    )
    
    for pattern in "${patterns[@]}"; do
      if grep -qE "$pattern" "$shell_file" 2>/dev/null; then
        if [[ "${DRY_RUN:-0}" == "1" ]]; then
          log "[DRY RUN] Would remove '$pattern' from $(basename "$shell_file")"
        else
          remove_lines_from_file "$shell_file" "$pattern"
          log "✓ Cleaned $(basename "$shell_file")"
        fi
      fi
    done
  done
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Rust uninstall simulation complete"
  else
    log "✓ Rust uninstall complete"
    log "⚠️  Restart your shell or run: source ~/.bashrc"
  fi
  
  return 0
}
