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
  local GO_VERSION="1.21.4"
  local GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
  local GO_INSTALL_DIR="/usr/local/go"
  local GO_CHECKSUM="47b26a83d2b65a3c1c1bcace273b69bee49a7a7b5168a7604ded3d26a37bd787"
  if [[ ! "$GO_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "ERROR: Invalid Go version format: $GO_VERSION"
    return 1
  fi
  local WORK_DIR
  WORK_DIR=$(mktemp -d) || {
    log "ERROR: Failed to create temporary directory"
    return 1
  }
  # shellcheck disable=SC2064
  trap "rm -rf '$WORK_DIR'" RETURN
  cd "$WORK_DIR" || {
    log "ERROR: Failed to change to temporary directory"
    return 1
  }
  if [[ ! -f "$GO_TAR" ]]; then
    curl -LO --retry 3 --retry-delay 2 --connect-timeout 10 \
      "https://go.dev/dl/${GO_TAR}"
  fi
  log "Verifying Go download checksum…"
  if ! echo "${GO_CHECKSUM}  ${GO_TAR}" | sha256sum -c --quiet; then
    log "ERROR: Go download checksum verification failed"
    rm -f "$GO_TAR"
    return 1
  fi
  if [[ -d "$GO_INSTALL_DIR" ]]; then
    log "Removing existing Go installation at $GO_INSTALL_DIR…"
    if ! validate_path "$GO_INSTALL_DIR" "/usr/local/go"; then
      return 1
    fi
    $(need_sudo) rm -rf "$GO_INSTALL_DIR"
  fi
  $(need_sudo) tar -C /usr/local -xzf "$GO_TAR"
  rm "$GO_TAR"
  local profile="$HOME/.bashrc"
  if ! grep -q '/usr/local/go/bin' "$profile" 2>/dev/null; then
    log "Adding Go to PATH in $profile…"
    cat >> "$profile" <<'EOF'
# Go configuration
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
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
