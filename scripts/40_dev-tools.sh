#!/usr/bin/env bash
# Ubuntu 24.04 development tools installation (idempotent).
# Docker, Node.js, Python, Rust, Go, VS Code, and essential dev utilities.

set -euo pipefail
IFS=$'\n\t'

# Source shared helpers for apt lock handling and DRY_RUN support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../hardware/common.sh"

log(){ printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then echo sudo; fi; }

# Docker installation (official repo)
install_docker(){
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return 0
  fi
  
  log "Installing Docker…"
  
  # Install prerequisites
  apt_safe update -qq
  apt_safe install -y ca-certificates curl gnupg
  
  # Add Docker's official GPG key
  $(need_sudo) install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $(need_sudo) gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $(need_sudo) chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  
  # Add repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    $(need_sudo) tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Install Docker
  apt_safe update -qq
  apt_safe install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  
  # Add user to docker group
  if ! groups "$USER" | grep -q docker; then
    log "Adding $USER to docker group…"
    $(need_sudo) usermod -aG docker "$USER"
    log "Docker group added. Log out and back in for changes to take effect."
  fi
  
  log "Docker installed successfully."
}

# Node.js via nvm (Node Version Manager)
install_nodejs(){
  local NVM_DIR="$HOME/.nvm"
  
  if [[ -d "$NVM_DIR" ]]; then
    log "nvm already installed at $NVM_DIR"
  else
    log "Installing nvm (Node Version Manager)…"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Source nvm for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  
  # Source nvm if available
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
      set +u
    \. "$NVM_DIR/nvm.sh"
    
    # Install Node LTS if not present
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

# Python via pyenv (Python version manager)
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
  curl https://pyenv.run | bash
  
  # Add to shell profile if not present
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

# Rust via rustup
install_rust(){
  if command -v rustc >/dev/null 2>&1; then
    log "Rust already installed: $(rustc --version)"
    return 0
  fi
  
  log "Installing Rust via rustup…"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  
  # Source cargo env
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
    log "Rust installed: $(rustc --version)"
  fi
}

# Go programming language
install_go(){
  if command -v go >/dev/null 2>&1; then
    log "Go already installed: $(go version)"
    return 0
  fi
  
  log "Installing Go…"
  local GO_VERSION="1.21.4"
  local GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
  
  cd /tmp
  curl -LO "https://go.dev/dl/${GO_TAR}"
  $(need_sudo) rm -rf /usr/local/go
  $(need_sudo) tar -C /usr/local -xzf "$GO_TAR"
  rm "$GO_TAR"
  
  # Add to PATH if not present
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

# VS Code (Microsoft official)
install_vscode(){
  if command -v code >/dev/null 2>&1; then
    log "VS Code already installed."
    return 0
  fi
  
  log "Installing VS Code…"
  
  # Add Microsoft GPG key
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | $(need_sudo) tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
  
  # Add repository
  echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    $(need_sudo) tee /etc/apt/sources.list.d/vscode.list
  
  # Install
  apt_safe update -qq
  apt_safe install -y code
  
  log "VS Code installed."
}

# Additional development utilities
install_dev_utilities(){
  local pkgs=(
    jq              # JSON processor
    tree            # Directory viewer
    httpie          # HTTP client
    ripgrep         # Fast grep alternative
    fd-find         # Fast find alternative
    tmux            # Terminal multiplexer
    sqlite3         # SQLite database
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

# Verification
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

main(){
  log "=== Development Tools Installation ==="
  install_docker
  install_nodejs
  install_python
  install_rust
  install_go
  install_vscode
  install_dev_utilities
  verify_installation
  log "Development tools installation complete."
  log ""
  log "IMPORTANT: Some tools require shell restart or re-login:"
  log "  - Docker: Log out/in to use without sudo"
  log "  - Node.js: Run 'source ~/.nvm/nvm.sh' or restart shell"
  log "  - Python: Run 'source ~/.bashrc' to enable pyenv"
  log "  - Rust: Run 'source ~/.cargo/env' or restart shell"
  log "  - Go: Run 'source ~/.bashrc' to update PATH"
}

main "$@"
