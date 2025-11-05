#!/usr/bin/env bash
# Module: Go programming language
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh" 2>/dev/null || true

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
validate_path() {
  local path="$1"
  local expected="$2"
  if [[ "$path" != "$expected" ]]; then
    log "ERROR: Path validation failed. Expected: $expected, Got: $path"
    return 1
  fi
  if [[ ! "$path" =~ ^${expected}$ ]]; then
    log "ERROR: Path regex validation failed for: $path"
    return 1
  fi
  return 0
}
install_go(){
  if command -v go >/dev/null 2>&1; then
    log "Go already installed: $(go version)"
    return 0
  fi
  log "Installing Go…"

  # Determine latest stable Go version and checksum for linux-amd64
  local GO_VERSION
  local GO_TAR
  local GO_INSTALL_DIR="/usr/local/go"
  local GO_CHECKSUM

  resolve_go_version_and_checksum() {
    local ver_json latest ver checksum
    if command -v jq >/dev/null 2>&1; then
      ver_json=$(curl -fsSL "https://go.dev/dl/?mode=json") || return 1
      # Latest stable version string like "go1.25.3"
      latest=$(echo "$ver_json" | jq -r '[.[] | select(.stable==true)][0].version') || return 1
      ver=${latest#go}
      checksum=$(echo "$ver_json" | jq -r ".[] | select(.version==\"${latest}\").files[] | select(.os==\"linux\" and .arch==\"amd64\" and .kind==\"archive\").sha256") || return 1
    else
      # Fallback without jq (best-effort parsing)
      latest=$(curl -fsSL "https://go.dev/dl/?mode=json" | sed -n 's/.*"version":"go\([0-9]\+\.[0-9]\+\.[0-9]\+\)".*"stable":true.*/\1/p' | head -n1) || return 1
      ver="$latest"
      # Fetch checksum page and try to extract the sha256
      checksum=$(curl -fsSL "https://go.dev/dl/" | awk -v v="go${ver}.linux-amd64.tar.gz" '
        $0 ~ v {found=1}
        found && $0 ~ /sha256/ { if (match($0, /sha256:([a-f0-9]{64})/, m)) { print m[1]; exit } }
      ') || true
    fi
    if [[ -z "${ver:-}" ]]; then return 1; fi
    GO_VERSION="$ver"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_CHECKSUM="$checksum"
    return 0
  }

  # Allow override via env for reproducibility
  if [[ -n "${GO_VERSION_OVERRIDE:-}" && -n "${GO_CHECKSUM_OVERRIDE:-}" ]]; then
    GO_VERSION="$GO_VERSION_OVERRIDE"
    GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
    GO_CHECKSUM="$GO_CHECKSUM_OVERRIDE"
  else
    if ! resolve_go_version_and_checksum; then
      log "ERROR: Failed to resolve latest Go version/checksum"
      return 1
    fi
  fi

  if [[ ! "$GO_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "ERROR: Invalid Go version format: $GO_VERSION"
    return 1
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would download ${GO_TAR} (sha256=${GO_CHECKSUM:-unknown}) and install to ${GO_INSTALL_DIR}"
    log "[DRY RUN] Would update PATH and GOPATH in ~/.bashrc"
    return 0
  fi
  local WORK_DIR
  WORK_DIR=$(mktemp -d) || { log "ERROR: Failed to create temporary directory"; return 1; }
  pushd "$WORK_DIR" >/dev/null || { log "ERROR: Failed to change to temporary directory"; rm -rf "$WORK_DIR"; return 1; }
  # Cleanup: return to previous dir, then remove temp dir
  # shellcheck disable=SC2064
  trap "popd >/dev/null 2>&1 || true; rm -rf '$WORK_DIR'" RETURN
  curl -LO --retry 3 --retry-delay 2 --connect-timeout 10 "https://go.dev/dl/${GO_TAR}"
  log "Verifying Go download checksum…"
  if [[ -n "${GO_CHECKSUM:-}" ]] && ! echo "${GO_CHECKSUM}  ${GO_TAR}" | sha256sum -c --quiet; then
    log "ERROR: Go download checksum verification failed"
    return 1
  fi
  if [[ -d "$GO_INSTALL_DIR" ]]; then
    log "Removing existing Go installation at $GO_INSTALL_DIR…"
    if ! validate_path "$GO_INSTALL_DIR" "/usr/local/go"; then return 1; fi
    $(need_sudo) rm -rf "$GO_INSTALL_DIR"
  fi
  $(need_sudo) tar -C /usr/local -xzf "$GO_TAR"
  local profile="$HOME/.bashrc"
  if ! grep -q '/usr/local/go/bin' "$profile" 2>/dev/null; then
    log "Adding Go to PATH in $profile…"
    cat >> "$profile" <<'EOF'
# Go configuration
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
EOF
  fi
  log "Go installed. Run 'source ~/.bashrc' to update PATH."
}

# Check if Go is installed
is_go_installed() {
  [[ -d "/usr/local/go" ]] && return 0
  command -v go >/dev/null 2>&1 && return 0
  return 1
}

# Backup Go configuration before uninstall
# shellcheck disable=SC2120
backup_go_config() {
  local backup_dir="${1:-$HOME/.config/bootstrap-backups/go-$(date +%Y%m%d-%H%M%S)}"
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would create backup directory: $backup_dir"
  else
    mkdir -p "$backup_dir"
    log "Created backup directory: $backup_dir"
  fi
  
  # Backup Go workspace if it exists
  if [[ -d "$HOME/go" ]]; then
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would backup ~/go directory list"
    else
      # Just save a list of what's in ~/go, not the full content
      find "$HOME/go" -maxdepth 3 -type f > "$backup_dir/go-workspace-files.txt" 2>/dev/null || true
      log "Backed up Go workspace file list"
    fi
  fi
  
  # Backup shell configurations
  for shell_file in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
    if [[ -f "$shell_file" ]] && grep -qE "GOPATH|/usr/local/go" "$shell_file" 2>/dev/null; then
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would backup $(basename "$shell_file")"
      else
        backup_shell_file "$shell_file" "$backup_dir"
      fi
    fi
  done
  
  echo "$backup_dir"
}

# Uninstall Go
# shellcheck disable=SC2120
uninstall_go() {
  log "Starting Go uninstall..."
  
  if ! is_go_installed; then
    log "Go is not installed. Nothing to uninstall."
    return 0
  fi
  
  # User confirmation (skip in FORCE or DRY_RUN mode)
  if [[ "${FORCE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
    echo "⚠️  This will remove:"
    echo "   - Go installation (/usr/local/go)"
    echo "   - Go-related shell configuration (PATH, GOPATH)"
    if [[ -d "$HOME/go" ]]; then
      echo "   - Your Go workspace (~/go) will be PRESERVED by default"
      echo "     (contains your projects and downloaded packages)"
    fi
    echo ""
    read -rp "Continue with Go uninstall? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log "Go uninstall cancelled by user."
      return 1
    fi
  fi
  
  # Create backup before uninstall
  local backup_dir
  backup_dir=$(backup_go_config)
  log "Backup location: $backup_dir"
  
  # Remove /usr/local/go directory (requires sudo)
  if [[ -d "/usr/local/go" ]]; then
    if ! validate_path "/usr/local/go" "/usr/local/go"; then
      log "ERROR: Safety check failed for /usr/local/go path"
      return 1
    fi
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      log "[DRY RUN] Would remove: /usr/local/go (with sudo)"
    else
      log "Removing /usr/local/go directory (requires sudo)..."
      $(need_sudo) rm -rf "/usr/local/go"
      log "✓ Removed /usr/local/go"
    fi
  fi
  
  # Clean up shell configurations
  local shell_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc")
  for shell_file in "${shell_files[@]}"; do
    if [[ ! -f "$shell_file" ]]; then
      continue
    fi
    
    # Patterns to remove (Go PATH and GOPATH configuration)
    local patterns=(
      'export GOPATH=.*'
      'export PATH=.*:/usr/local/go/bin.*'
      'export PATH=.*:\$GOPATH/bin.*'
      '.*Go configuration.*'
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
  
  # Ask about ~/go directory (contains user projects and packages)
  if [[ -d "$HOME/go" && "${FORCE:-0}" != "1" && "${DRY_RUN:-0}" != "1" ]]; then
    echo ""
    echo "⚠️  IMPORTANT: Your Go workspace directory exists at ~/go"
    echo "   This contains:"
    echo "   - Your Go projects (~/go/src)"
    echo "   - Downloaded packages (~/go/pkg)"
    echo "   - Compiled binaries (~/go/bin)"
    echo ""
    read -rp "Do you want to REMOVE ~/go directory? [y/N] " remove_workspace
    if [[ "$remove_workspace" =~ ^[Yy]$ ]]; then
      if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log "[DRY RUN] Would remove: ~/go"
      else
        log "Removing ~/go directory..."
        rm -rf "$HOME/go"
        log "✓ Removed ~/go"
      fi
    else
      log "Preserving ~/go directory (your projects are safe)"
    fi
  elif [[ -d "$HOME/go" && "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Would ask about removing ~/go directory"
  fi
  
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "[DRY RUN] Go uninstall simulation complete"
  else
    log "✓ Go uninstall complete"
    log "⚠️  Restart your shell or run: source ~/.bashrc"
  fi
  
  return 0
}

# Uninstall/rollback stub (keeping old name for backward compatibility)
uninstall_go_old(){
  log "[UNINSTALL] Go uninstall not yet implemented."
  # Example: $(need_sudo) rm -rf /usr/local/go "$HOME/go"
  return 0
}
