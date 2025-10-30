#!/usr/bin/env bash
# Module: Go programming language
set -euo pipefail
IFS=$'\n\t'

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

# Uninstall/rollback stub
uninstall_go(){
  log "[UNINSTALL] Go uninstall not yet implemented."
  # Example: $(need_sudo) rm -rf /usr/local/go "$HOME/go"
  return 0
}
