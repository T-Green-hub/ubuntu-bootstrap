#!/usr/bin/env bash

# Ubuntu 24.04 development tools installation (modular).
# Docker, Node.js, Python, Rust, Go, VS Code, and essential dev utilities.
#
# This script now orchestrates modular install scripts in scripts/dev-modules/.
# Each module is independently testable and sourceable.
#
# To add/remove tools, edit the modules in scripts/dev-modules/ and update the list below.
#
# Usage: ./40_dev-tools.sh [tool ...]
#   If no arguments, installs all tools. Otherwise, installs only specified tools.

# Each module must provide both install_<tool> and uninstall_<tool> functions for advanced validation/rollback.
# Example: install_docker, uninstall_docker

set -euo pipefail
IFS=$'\n\t'

# Source shared helpers for apt lock handling and DRY_RUN support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"


log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# List of tool modules and their install functions
DEV_MODULES=(
  "docker:install_docker"
  "nodejs:install_nodejs"
  "python:install_python"
  "rust:install_rust"
  "go:install_go"
  "vscode:install_vscode"
  "utilities:install_dev_utilities"
)


# Source all modules (shellcheck disable for dynamic source)
# shellcheck source=dev-modules/docker.sh
# shellcheck source=dev-modules/nodejs.sh
# shellcheck source=dev-modules/python.sh
# shellcheck source=dev-modules/rust.sh
# shellcheck source=dev-modules/go.sh
# shellcheck source=dev-modules/vscode.sh
# shellcheck source=dev-modules/utilities.sh
for mod in "${DEV_MODULES[@]}"; do
  name="${mod%%:*}"
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/dev-modules/${name}.sh"
done


# Move main and verify_installation to top so main is defined before being called
main(){
  log "=== Development Tools Installation (Modular) ==="

  local failed_tools=()
  local to_install=()

  # If arguments given, only install those tools
  if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
      found=0
      for mod in "${DEV_MODULES[@]}"; do
        name="${mod%%:*}"
        func="${mod##*:}"
        if [[ "$arg" == "$name" ]]; then
          to_install+=("$mod")
          found=1
          break
        fi
      done
      if [[ $found -eq 0 ]]; then
        log "WARNING: Unknown tool: $arg"
      fi
    done
  else
    to_install=("${DEV_MODULES[@]}")
  fi

  # Install tools with individual error tracking
  for mod in "${to_install[@]}"; do
    name="${mod%%:*}"
    func="${mod##*:}"
    log "Installing $name…"
    if ! $func; then
      failed_tools+=("$name")
    fi
  done

  verify_installation

  # Report results
  if [[ ${#failed_tools[@]} -gt 0 ]]; then
    log "WARNING: Some installations failed: ${failed_tools[*]}"
    log "Development tools installation completed with errors."
  else
    log "Development tools installation complete - all tools succeeded."
  fi

  log ""
  log "IMPORTANT: Some tools require shell restart or re-login:"
  log "  - Docker: Log out/in to use without sudo"
  log "  - Node.js: Run 'source ~/.nvm/nvm.sh' or restart shell"
  log "  - Python: Run 'source ~/.bashrc' to enable pyenv"
  log "  - Rust: Run 'source ~/.cargo/env' or restart shell"
  log "  - Go: Run 'source ~/.bashrc' to update PATH"

  # Return non-zero if any tools failed
  if [[ ${#failed_tools[@]} -gt 0 ]]; then
    return 1
  fi
}

verify_installation(){
  log "Verifying installed tools…"
  command -v docker >/dev/null 2>&1 && log "✓ Docker: $(docker --version)"
  command -v node >/dev/null 2>&1 && log "✓ Node.js: $(node --version)"
  command -v npm >/dev/null 2>&1 && log "✓ npm: $(npm --version)"
  command -v python3 >/dev/null 2>&1 && log "✓ Python: $(python3 --version)"
  command -v rustc >/dev/null 2>&1 && log "✓ Rust: $(rustc --version)"
  command -v go >/dev/null 2>&1 && log "✓ Go: $(go version)"
  command -v code >/dev/null 2>&1 && log "✓ VS Code installed"
  command -v jq >/dev/null 2>&1 && log "✓ jq: $(jq --version)"
  log "Verification complete."
}

main "$@"
