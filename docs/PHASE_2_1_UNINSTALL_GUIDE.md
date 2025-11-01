# Phase 2.1 Implementation Guide: Uninstall/Rollback

**Priority:** 🔴 CRITICAL  
**Timeline:** Weeks 1-2 (Nov 4-15, 2025)  
**Owner:** Core maintainer  
**Status:** Ready to implement

---

## Overview

This guide provides step-by-step instructions for implementing proper uninstall functionality across all dev-modules. This is the **highest priority** task because it blocks safe experimentation and testing.

---

## Pre-Implementation Checklist

- [ ] Read through this entire guide
- [ ] Review current uninstall stubs in all dev-modules
- [ ] Set up test environment (VM or Docker recommended)
- [ ] Create feature branch: `git checkout -b feature/uninstall-implementation`
- [ ] Backup your current system before testing

---

## Implementation Order

Implement in order of increasing complexity:

1. ✅ **utilities.sh** (Easiest - just apt packages)
2. ✅ **vscode.sh** (Simple - apt + repo cleanup)
3. ✅ **nodejs.sh** (Medium - directory removal + .bashrc)
4. ✅ **python.sh** (Medium - directory removal + .bashrc)
5. ✅ **rust.sh** (Medium - rustup self-uninstall)
6. ✅ **go.sh** (Medium - directory removal + PATH)
7. ✅ **docker.sh** (Hardest - packages + groups + configs + data)

---

## Standard Uninstall Function Template

Every module should follow this structure:

```bash
# scripts/dev-modules/<module>.sh

# Detection function - check if module is installed
is_<module>_installed() {
  # Check for command existence, files, or packages
  if command -v <tool> >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Backup function - save important user data
backup_<module>_config() {
  local backup_dir="$HOME/.local/share/ubuntu-bootstrap/backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir/<module>"
  
  # Backup configs
  if [[ -d "$HOME/.<module>rc" ]]; then
    cp -a "$HOME/.<module>rc" "$backup_dir/<module>/"
    log "[BACKUP] Saved .<module>rc to $backup_dir"
  fi
  
  # Save list of installed packages/versions
  <tool> --version > "$backup_dir/<module>/version.txt" 2>&1 || true
}

# Service stop function - stop running services
stop_<module>_services() {
  # Only needed for services like Docker
  if systemctl is-active --quiet <service>; then
    log "[UNINSTALL] Stopping <service>..."
    sudo systemctl stop <service>
  fi
}

# Package removal function
remove_<module>_packages() {
  local packages=("package1" "package2" "package3")
  
  for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
      log "[UNINSTALL] Removing package: $pkg"
      if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log "  [DRY RUN] Would run: apt-get remove -y $pkg"
      else
        sudo apt-get remove -y "$pkg"
      fi
    fi
  done
  
  # Cleanup PPAs/repos if added
  if [[ -f /etc/apt/sources.list.d/<module>.list ]]; then
    log "[UNINSTALL] Removing repository"
    sudo rm -f /etc/apt/sources.list.d/<module>.list
  fi
}

# Data cleanup function - remove user data directories
clean_<module>_data() {
  local dirs_to_remove=(
    "$HOME/.<module>"
    "$HOME/.config/<module>"
    "$HOME/.local/share/<module>"
    "$HOME/.cache/<module>"
  )
  
  for dir in "${dirs_to_remove[@]}"; do
    if [[ -d "$dir" ]]; then
      log "[UNINSTALL] Removing directory: $dir"
      
      # Safety check: ensure we're not removing $HOME
      if [[ "$dir" == "$HOME" ]] || [[ "$dir" == "/" ]]; then
        log "ERROR: Attempted to remove protected path: $dir"
        return 1
      fi
      
      if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log "  [DRY RUN] Would run: rm -rf $dir"
      else
        rm -rf "$dir"
      fi
    fi
  done
}

# PATH cleanup function - remove from shell configs
clean_<module>_path() {
  local shell_configs=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")
  
  for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
      # Remove lines added by this module
      local marker_start="# >>> <module> initialization >>>"
      local marker_end="# <<< <module> initialization <<<"
      
      if grep -q "$marker_start" "$config"; then
        log "[UNINSTALL] Cleaning $config"
        
        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
          log "  [DRY RUN] Would remove <module> block from $config"
        else
          # Create temp file without the marked section
          sed "/$marker_start/,/$marker_end/d" "$config" > "$config.tmp"
          mv "$config.tmp" "$config"
        fi
      fi
    fi
  done
}

# Verification function - check removal was successful
verify_<module>_removed() {
  local errors=0
  
  # Check command not available
  if command -v <tool> >/dev/null 2>&1; then
    log "[VERIFY] ERROR: <tool> command still available"
    errors=$((errors + 1))
  fi
  
  # Check directories removed
  if [[ -d "$HOME/.<module>" ]]; then
    log "[VERIFY] ERROR: $HOME/.<module> still exists"
    errors=$((errors + 1))
  fi
  
  # Check PATH cleaned
  if grep -q "<module>" "$HOME/.bashrc" 2>/dev/null; then
    log "[VERIFY] ERROR: <module> references still in .bashrc"
    errors=$((errors + 1))
  fi
  
  if [[ $errors -eq 0 ]]; then
    log "[VERIFY] ✓ <Module> successfully removed"
    return 0
  else
    log "[VERIFY] ✗ <Module> removal incomplete ($errors issues)"
    return 1
  fi
}

# Main uninstall function
uninstall_<module>() {
  log "[UNINSTALL] Starting <Module> uninstall..."
  
  # 1. Check if installed
  if ! is_<module>_installed; then
    log "[UNINSTALL] <Module> not installed, skipping"
    return 0
  fi
  
  # 2. Confirm with user (unless FORCE=1)
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    echo ""
    echo "WARNING: This will remove <Module> and all its data."
    echo "Configs will be backed up to ~/.local/share/ubuntu-bootstrap/backups/"
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "[UNINSTALL] Cancelled by user"
      return 0
    fi
  fi
  
  # 3. Backup configs
  backup_<module>_config
  
  # 4. Stop services (if applicable)
  stop_<module>_services
  
  # 5. Remove packages
  remove_<module>_packages
  
  # 6. Clean user data
  clean_<module>_data
  
  # 7. Clean PATH entries
  clean_<module>_path
  
  # 8. Verify removal
  verify_<module>_removed
  
  log "[UNINSTALL] <Module> uninstall complete"
}
```

---

## Module-Specific Implementation

### 1. utilities.sh (START HERE - Easiest)

**Current State:** Just apt packages, no complex state

**Implementation:**

```bash
# scripts/dev-modules/utilities.sh

is_utilities_installed() {
  # Check if any of the utilities are installed
  local tools=("jq" "ripgrep" "fd-find" "httpie" "tree" "tmux")
  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

backup_utilities_config() {
  # Utilities typically don't have config files
  # But save the list of what was installed
  local backup_dir="$HOME/.local/share/ubuntu-bootstrap/backups/$(date +%Y%m%d-%H%M%S)/utilities"
  mkdir -p "$backup_dir"
  
  dpkg -l | grep -E "jq|ripgrep|fd-find|httpie|tree|tmux|sqlite3" > "$backup_dir/installed.txt"
  log "[BACKUP] Saved utilities list to $backup_dir/installed.txt"
}

stop_utilities_services() {
  # No services to stop
  return 0
}

remove_utilities_packages() {
  local packages=(
    "jq"
    "tree"
    "httpie"
    "ripgrep"
    "fd-find"
    "tmux"
    "sqlite3"
    "ncdu"
    "htop"
  )
  
  log "[UNINSTALL] Removing dev utility packages..."
  
  for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
      if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log "  [DRY RUN] Would remove: $pkg"
      else
        sudo apt-get remove -y "$pkg" || log "Warning: Failed to remove $pkg"
      fi
    fi
  done
}

clean_utilities_data() {
  # No persistent data directories for these utilities
  return 0
}

clean_utilities_path() {
  # No PATH modifications for these utilities
  return 0
}

verify_utilities_removed() {
  local errors=0
  local tools=("jq" "rg" "fdfind" "http" "tree" "tmux")
  
  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      log "[VERIFY] WARNING: $tool still available (may be from other source)"
      # Note: Don't increment errors - might be from other install
    fi
  done
  
  log "[VERIFY] ✓ Dev utilities uninstall complete"
  return 0
}

uninstall_dev_utilities() {
  log "[UNINSTALL] Starting dev utilities uninstall..."
  
  if ! is_utilities_installed; then
    log "[UNINSTALL] Dev utilities not detected, skipping"
    return 0
  fi
  
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    read -p "Remove dev utilities (jq, ripgrep, fd-find, etc.)? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
  fi
  
  backup_utilities_config
  stop_utilities_services
  remove_utilities_packages
  clean_utilities_data
  clean_utilities_path
  verify_utilities_removed
  
  log "[UNINSTALL] Dev utilities uninstall complete"
}
```

**Testing Checklist:**
- [ ] Install utilities: `bash scripts/dev-modules/utilities.sh`
- [ ] Verify tools work: `jq --version`, `rg --version`, etc.
- [ ] Run uninstall: `bash -c 'source scripts/dev-modules/utilities.sh && uninstall_dev_utilities'`
- [ ] Verify removal: commands should not exist
- [ ] Check backup created in `~/.local/share/ubuntu-bootstrap/backups/`

---

### 2. nodejs.sh

**Complexity:** Medium (nvm directory + .bashrc modifications)

**Key Challenges:**
- Remove `~/.nvm` directory (can be large)
- Clean nvm block from .bashrc
- Handle multiple Node versions

**Implementation:**

```bash
# scripts/dev-modules/nodejs.sh

is_nodejs_installed() {
  [[ -d "$HOME/.nvm" ]] && return 0
  command -v nvm >/dev/null 2>&1 && return 0
  return 1
}

backup_nodejs_config() {
  local backup_dir="$HOME/.local/share/ubuntu-bootstrap/backups/$(date +%Y%m%d-%H%M%S)/nodejs"
  mkdir -p "$backup_dir"
  
  # Backup .npmrc if exists
  if [[ -f "$HOME/.npmrc" ]]; then
    cp "$HOME/.npmrc" "$backup_dir/"
  fi
  
  # Save list of installed Node versions and global packages
  if [[ -d "$HOME/.nvm" ]]; then
    ls -1 "$HOME/.nvm/versions/node/" > "$backup_dir/node_versions.txt" 2>/dev/null || true
    
    # Try to save global packages
    if command -v npm >/dev/null 2>&1; then
      npm list -g --depth=0 > "$backup_dir/global_packages.txt" 2>/dev/null || true
    fi
  fi
  
  log "[BACKUP] Saved Node.js config to $backup_dir"
}

stop_nodejs_services() {
  # No services to stop
  return 0
}

remove_nodejs_packages() {
  # nvm is not a package, it's a directory
  # No apt packages to remove
  return 0
}

clean_nodejs_data() {
  if [[ -d "$HOME/.nvm" ]]; then
    log "[UNINSTALL] Removing nvm directory: $HOME/.nvm"
    
    # Safety check
    if [[ "$HOME/.nvm" == "$HOME" ]] || [[ "$HOME/.nvm" == "/" ]]; then
      log "ERROR: Invalid nvm path detected"
      return 1
    fi
    
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
      log "  [DRY RUN] Would run: rm -rf $HOME/.nvm"
    else
      # Get size before removal
      local size=$(du -sh "$HOME/.nvm" 2>/dev/null | cut -f1)
      rm -rf "$HOME/.nvm"
      log "  Freed disk space: ~$size"
    fi
  fi
  
  # Remove npm cache
  if [[ -d "$HOME/.npm" ]]; then
    log "[UNINSTALL] Removing npm cache: $HOME/.npm"
    if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
      rm -rf "$HOME/.npm"
    fi
  fi
}

clean_nodejs_path() {
  local shell_configs=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")
  
  for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
      # Remove nvm initialization block
      if grep -q "NVM_DIR" "$config"; then
        log "[UNINSTALL] Cleaning $config"
        
        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
          log "  [DRY RUN] Would remove nvm block from $config"
        else
          # Remove lines between nvm markers or common nvm patterns
          sed -i '/export NVM_DIR/d' "$config"
          sed -i '/\[ -s.*nvm\.sh/d' "$config"
          sed -i '/\[ -s.*bash_completion/d' "$config"
          sed -i '/# >>> nvm initialization >>>/,/# <<< nvm initialization <<</d' "$config"
        fi
      fi
    fi
  done
}

verify_nodejs_removed() {
  local errors=0
  
  if [[ -d "$HOME/.nvm" ]]; then
    log "[VERIFY] ERROR: $HOME/.nvm still exists"
    errors=$((errors + 1))
  fi
  
  if command -v nvm >/dev/null 2>&1; then
    log "[VERIFY] ERROR: nvm command still available"
    errors=$((errors + 1))
  fi
  
  if grep -q "NVM_DIR" "$HOME/.bashrc" 2>/dev/null; then
    log "[VERIFY] ERROR: NVM_DIR still in .bashrc"
    errors=$((errors + 1))
  fi
  
  if [[ $errors -eq 0 ]]; then
    log "[VERIFY] ✓ Node.js/nvm successfully removed"
    return 0
  else
    log "[VERIFY] ✗ Node.js/nvm removal incomplete ($errors issues)"
    return 1
  fi
}

uninstall_nodejs() {
  log "[UNINSTALL] Starting Node.js/nvm uninstall..."
  
  if ! is_nodejs_installed; then
    log "[UNINSTALL] Node.js/nvm not installed, skipping"
    return 0
  fi
  
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    echo ""
    echo "WARNING: This will remove:"
    echo "  - nvm and all installed Node.js versions"
    echo "  - All global npm packages"
    echo "  - npm cache"
    echo ""
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
  fi
  
  backup_nodejs_config
  stop_nodejs_services
  remove_nodejs_packages
  clean_nodejs_data
  clean_nodejs_path
  verify_nodejs_removed
  
  log "[UNINSTALL] Node.js/nvm uninstall complete"
  log "NOTE: Restart shell or run: source ~/.bashrc"
}
```

**Testing Checklist:**
- [ ] Install Node.js: `bash scripts/dev-modules/nodejs.sh`
- [ ] Install some global packages: `npm install -g yarn typescript`
- [ ] Verify nvm works: `nvm --version`, `node --version`
- [ ] Run uninstall: `bash -c 'source scripts/dev-modules/nodejs.sh && uninstall_nodejs'`
- [ ] Verify `~/.nvm` directory removed
- [ ] Verify `.bashrc` cleaned (no NVM_DIR)
- [ ] Open new shell, verify `nvm` command not found

---

### 7. docker.sh (Most Complex - Do Last)

**Complexity:** High (packages + groups + services + optional rootless + data)

**Key Challenges:**
- Remove user from docker group
- Handle both regular and rootless installations
- Clean up container images/volumes (optional)
- Remove multiple apt packages

**Implementation:**

```bash
# scripts/dev-modules/docker.sh

is_docker_installed() {
  command -v docker >/dev/null 2>&1 && return 0
  dpkg -l | grep -q "^ii  docker-ce" && return 0
  return 1
}

backup_docker_config() {
  local backup_dir="$HOME/.local/share/ubuntu-bootstrap/backups/$(date +%Y%m%d-%H%M%S)/docker"
  mkdir -p "$backup_dir"
  
  # Backup Docker configs
  if [[ -d "$HOME/.docker" ]]; then
    cp -a "$HOME/.docker" "$backup_dir/"
  fi
  
  # Save list of images and containers
  if command -v docker >/dev/null 2>&1; then
    docker images > "$backup_dir/images.txt" 2>/dev/null || true
    docker ps -a > "$backup_dir/containers.txt" 2>/dev/null || true
    docker volume ls > "$backup_dir/volumes.txt" 2>/dev/null || true
  fi
  
  log "[BACKUP] Saved Docker config to $backup_dir"
}

stop_docker_services() {
  if systemctl is-active --quiet docker; then
    log "[UNINSTALL] Stopping Docker service..."
    if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
      sudo systemctl stop docker
      sudo systemctl disable docker
    fi
  fi
  
  if systemctl is-active --quiet containerd; then
    log "[UNINSTALL] Stopping containerd service..."
    if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
      sudo systemctl stop containerd
      sudo systemctl disable containerd
    fi
  fi
}

remove_docker_packages() {
  local packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
  )
  
  log "[UNINSTALL] Removing Docker packages..."
  
  for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
      if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log "  [DRY RUN] Would remove: $pkg"
      else
        sudo apt-get remove -y "$pkg" || log "Warning: Failed to remove $pkg"
      fi
    fi
  done
  
  # Remove Docker repository
  if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
    log "[UNINSTALL] Removing Docker repository"
    if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
      sudo rm -f /etc/apt/sources.list.d/docker.list
      sudo rm -f /etc/apt/keyrings/docker.gpg
    fi
  fi
}

clean_docker_data() {
  # Ask user if they want to remove images/containers
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    echo ""
    read -p "Also remove all Docker images, containers, and volumes? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      if command -v docker >/dev/null 2>&1; then
        log "[UNINSTALL] Removing all Docker containers, images, and volumes..."
        docker rm -f $(docker ps -aq) 2>/dev/null || true
        docker rmi -f $(docker images -q) 2>/dev/null || true
        docker volume rm $(docker volume ls -q) 2>/dev/null || true
      fi
    fi
  fi
  
  # Remove Docker system directories
  local dirs_to_remove=(
    "/var/lib/docker"
    "/var/lib/containerd"
    "$HOME/.docker"
  )
  
  for dir in "${dirs_to_remove[@]}"; do
    if [[ -d "$dir" ]]; then
      log "[UNINSTALL] Removing directory: $dir"
      
      if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        log "  [DRY RUN] Would run: rm -rf $dir"
      else
        if [[ "$dir" == /var/* ]]; then
          sudo rm -rf "$dir"
        else
          rm -rf "$dir"
        fi
      fi
    fi
  done
}

clean_docker_path() {
  # Remove user from docker group
  if groups | grep -q docker; then
    log "[UNINSTALL] Removing user from docker group..."
    if [[ "${DRY_RUN:-0}" -eq 0 ]]; then
      sudo deluser "$USER" docker || true
    fi
  fi
  
  # No PATH modifications typically for Docker
  return 0
}

verify_docker_removed() {
  local errors=0
  
  if command -v docker >/dev/null 2>&1; then
    log "[VERIFY] ERROR: docker command still available"
    errors=$((errors + 1))
  fi
  
  if dpkg -l | grep -q "^ii  docker-ce"; then
    log "[VERIFY] ERROR: docker-ce package still installed"
    errors=$((errors + 1))
  fi
  
  if systemctl is-active --quiet docker 2>/dev/null; then
    log "[VERIFY] ERROR: Docker service still running"
    errors=$((errors + 1))
  fi
  
  if groups | grep -q docker; then
    log "[VERIFY] WARNING: User still in docker group (logout/login required)"
  fi
  
  if [[ $errors -eq 0 ]]; then
    log "[VERIFY] ✓ Docker successfully removed"
    log "NOTE: Logout and login for group changes to take effect"
    return 0
  else
    log "[VERIFY] ✗ Docker removal incomplete ($errors issues)"
    return 1
  fi
}

uninstall_docker() {
  log "[UNINSTALL] Starting Docker uninstall..."
  
  if ! is_docker_installed; then
    log "[UNINSTALL] Docker not installed, skipping"
    return 0
  fi
  
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    echo ""
    echo "WARNING: This will remove:"
    echo "  - Docker Engine and all related packages"
    echo "  - Docker configuration files"
    echo "  - You will be prompted about images/containers/volumes"
    echo ""
    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
  fi
  
  backup_docker_config
  stop_docker_services
  remove_docker_packages
  clean_docker_data
  clean_docker_path
  verify_docker_removed
  
  log "[UNINSTALL] Docker uninstall complete"
  log "NOTE: Logout and login to complete group removal"
}
```

**Testing Checklist:**
- [ ] Install Docker: `bash scripts/dev-modules/docker.sh`
- [ ] Pull test image: `docker pull hello-world`
- [ ] Run test container: `docker run hello-world`
- [ ] Create test volume: `docker volume create test-vol`
- [ ] Run uninstall: `bash -c 'source scripts/dev-modules/docker.sh && uninstall_docker'`
- [ ] Verify packages removed: `dpkg -l | grep docker`
- [ ] Verify service stopped: `systemctl status docker`
- [ ] Verify `/var/lib/docker` removed
- [ ] Logout/login and verify user not in docker group: `groups`

---

## Central Uninstall Orchestrator

Create `scripts/uninstall_bootstrap.sh`:

```bash
#!/usr/bin/env bash
# Central uninstall orchestrator for ubuntu-bootstrap
# Usage:
#   ./uninstall_bootstrap.sh              # Interactive mode
#   ./uninstall_bootstrap.sh --all        # Uninstall everything
#   ./uninstall_bootstrap.sh docker nodejs  # Uninstall specific modules
#   DRY_RUN=1 ./uninstall_bootstrap.sh --all  # Preview only

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

# Source all dev-modules
for module in "$SCRIPT_DIR"/dev-modules/*.sh; do
  source "$module"
done

# Interactive selection menu
interactive_uninstall() {
  echo ""
  echo "=== Ubuntu Bootstrap Uninstall ==="
  echo ""
  echo "Select modules to uninstall (space-separated numbers):"
  echo ""
  echo "  1) Docker"
  echo "  2) Node.js (nvm)"
  echo "  3) Python (pyenv)"
  echo "  4) Rust (rustup)"
  echo "  5) Go"
  echo "  6) VS Code"
  echo "  7) Dev Utilities (jq, ripgrep, etc.)"
  echo ""
  echo "  8) All of the above"
  echo "  0) Cancel"
  echo ""
  read -p "Choice (e.g., 1 2 3): " -a choices
  
  for choice in "${choices[@]}"; do
    case "$choice" in
      1) uninstall_docker ;;
      2) uninstall_nodejs ;;
      3) uninstall_python ;;
      4) uninstall_rust ;;
      5) uninstall_go ;;
      6) uninstall_vscode ;;
      7) uninstall_dev_utilities ;;
      8)
        # Uninstall in reverse order of typical dependencies
        uninstall_dev_utilities
        uninstall_vscode
        uninstall_go
        uninstall_rust
        uninstall_python
        uninstall_nodejs
        uninstall_docker
        ;;
      0)
        log "Uninstall cancelled"
        exit 0
        ;;
      *)
        log "Invalid choice: $choice"
        ;;
    esac
  done
}

# Batch uninstall by module names
batch_uninstall() {
  local modules=("$@")
  
  for module in "${modules[@]}"; do
    case "$module" in
      docker) uninstall_docker ;;
      nodejs|node) uninstall_nodejs ;;
      python|pyenv) uninstall_python ;;
      rust|rustup) uninstall_rust ;;
      go|golang) uninstall_go ;;
      vscode|code) uninstall_vscode ;;
      utilities|utils) uninstall_dev_utilities ;;
      *)
        log "Unknown module: $module"
        log "Available modules: docker, nodejs, python, rust, go, vscode, utilities"
        ;;
    esac
  done
}

# Uninstall everything
uninstall_all() {
  log "Uninstalling all dev-modules..."
  
  if [[ "${FORCE:-0}" -eq 0 ]] && [[ "${DRY_RUN:-0}" -eq 0 ]]; then
    echo ""
    echo "WARNING: This will remove ALL dev tools installed by ubuntu-bootstrap:"
    echo "  - Docker"
    echo "  - Node.js (nvm)"
    echo "  - Python (pyenv)"
    echo "  - Rust (rustup)"
    echo "  - Go"
    echo "  - VS Code"
    echo "  - Dev Utilities"
    echo ""
    read -p "Are you SURE you want to continue? [y/N] " -n 1 -r
    echo ""
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
  fi
  
  # Uninstall in reverse order of installation (handle dependencies)
  uninstall_dev_utilities
  uninstall_vscode
  uninstall_go
  uninstall_rust
  uninstall_python
  uninstall_nodejs
  uninstall_docker
  
  log "All dev-modules uninstalled"
}

# Show help
show_help() {
  cat <<EOF
Ubuntu Bootstrap Uninstall Tool

Usage:
  $0                      Interactive mode (menu)
  $0 --all                Uninstall all dev-modules
  $0 MODULE [MODULE...]   Uninstall specific modules

Modules:
  docker      Docker Engine
  nodejs      Node.js (nvm)
  python      Python (pyenv)
  rust        Rust (rustup)
  go          Go language
  vscode      Visual Studio Code
  utilities   Dev utilities (jq, ripgrep, etc.)

Environment Variables:
  DRY_RUN=1   Preview actions without making changes
  FORCE=1     Skip confirmation prompts

Examples:
  $0                         # Interactive menu
  $0 --all                   # Remove everything
  $0 docker nodejs           # Remove only Docker and Node.js
  DRY_RUN=1 $0 --all         # Preview full uninstall
  FORCE=1 $0 docker          # Remove Docker without prompts

Backups:
  Configs are backed up to:
  ~/.local/share/ubuntu-bootstrap/backups/<timestamp>/

Notes:
  - Uninstall is performed in safe order (reverse of install)
  - User data is backed up before removal
  - Some changes require logout/login (e.g., group membership)

EOF
}

# Main entry point
main() {
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY RUN MODE - no changes will be made"
  fi
  
  if [[ $# -eq 0 ]]; then
    # No arguments: interactive mode
    interactive_uninstall
  elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
  elif [[ "$1" == "--all" ]]; then
    uninstall_all
  else
    # Specific modules
    batch_uninstall "$@"
  fi
  
  log "Uninstall process complete"
  log "Backups stored in: ~/.local/share/ubuntu-bootstrap/backups/"
}

main "$@"
```

**Make executable:**
```bash
chmod +x scripts/uninstall_bootstrap.sh
```

---

## Testing Strategy

### Unit Testing (Per Module)

For each module, create a test script:

```bash
# scripts/dev-modules/test_<module>_uninstall.sh
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/<module>.sh"

test_install_and_uninstall() {
  echo "TEST: Full install → uninstall cycle"
  
  # Install
  install_<module>
  
  # Verify installed
  if ! is_<module>_installed; then
    echo "FAIL: Module not installed after install"
    exit 1
  fi
  
  # Uninstall
  FORCE=1 uninstall_<module>
  
  # Verify removed
  if is_<module>_installed; then
    echo "FAIL: Module still installed after uninstall"
    exit 1
  fi
  
  echo "PASS: Install → uninstall cycle successful"
}

test_uninstall_when_not_installed() {
  echo "TEST: Uninstall when not installed"
  
  # Should return 0 and log message
  uninstall_<module>
  
  echo "PASS: Handles not-installed case gracefully"
}

test_dry_run_uninstall() {
  echo "TEST: Dry-run uninstall"
  
  # Install first
  install_<module>
  
  # Dry-run uninstall (should not remove)
  DRY_RUN=1 FORCE=1 uninstall_<module>
  
  # Verify still installed
  if ! is_<module>_installed; then
    echo "FAIL: Dry-run actually removed module"
    exit 1
  fi
  
  # Real uninstall
  FORCE=1 uninstall_<module>
  
  echo "PASS: Dry-run does not remove module"
}

# Run all tests
test_install_and_uninstall
test_uninstall_when_not_installed
test_dry_run_uninstall

echo ""
echo "All tests passed for <module> uninstall!"
```

### Integration Testing

Test the full uninstall orchestrator:

```bash
# test_uninstall_orchestrator.sh
#!/usr/bin/env bash
set -euo pipefail

echo "TEST: Uninstall orchestrator"

# Test 1: Help output
./scripts/uninstall_bootstrap.sh --help > /dev/null
echo "PASS: Help output works"

# Test 2: Dry-run all
DRY_RUN=1 FORCE=1 ./scripts/uninstall_bootstrap.sh --all
echo "PASS: Dry-run --all works"

# Test 3: Specific module dry-run
DRY_RUN=1 FORCE=1 ./scripts/uninstall_bootstrap.sh utilities
echo "PASS: Specific module dry-run works"

echo ""
echo "All orchestrator tests passed!"
```

---

## Makefile Integration

Add to `Makefile`:

```makefile
uninstall: ## Interactive uninstall of dev-modules
> "$(DIR)/scripts/uninstall_bootstrap.sh"

uninstall-all: ## Uninstall all dev-modules (with confirmation)
> "$(DIR)/scripts/uninstall_bootstrap.sh" --all

uninstall-dry: ## Preview uninstall without making changes
> DRY_RUN=1 "$(DIR)/scripts/uninstall_bootstrap.sh" --all
```

---

## Documentation Updates

Update these docs after implementation:

1. **README.md** - Add uninstall section:
```markdown
## Uninstalling

Remove specific tools:
```bash
bash scripts/uninstall_bootstrap.sh docker nodejs
```

Remove everything:
```bash
bash scripts/uninstall_bootstrap.sh --all
# or
make uninstall-all
```

Preview uninstall:
```bash
DRY_RUN=1 make uninstall-all
```
```

2. **Create docs/UNINSTALL.md** with comprehensive guide

3. **Update RELEASE_NOTES.md** for next release

---

## Success Criteria

Before marking Phase 2.1 complete, verify:

- [ ] All 7 dev-modules have working `uninstall_*()` functions
- [ ] Central orchestrator (`uninstall_bootstrap.sh`) works in all modes
- [ ] All modules create backups before removal
- [ ] `DRY_RUN=1` previews without making changes
- [ ] `FORCE=1` skips all confirmation prompts
- [ ] Verification functions correctly detect removal
- [ ] No protected paths (/, $HOME) can be removed
- [ ] Each module has unit tests for uninstall
- [ ] Integration tests pass for orchestrator
- [ ] Makefile targets work (`make uninstall`, `make uninstall-all`)
- [ ] Documentation updated (README, UNINSTALL.md)
- [ ] Manual testing on clean VM successful
- [ ] No "not yet implemented" messages remain

---

## Timeline

- **Day 1-2:** utilities.sh + vscode.sh (easiest)
- **Day 3-5:** nodejs.sh + python.sh (medium)
- **Day 6-8:** rust.sh + go.sh (medium)
- **Day 9-12:** docker.sh (hardest)
- **Day 13-14:** Central orchestrator + testing
- **Day 15-16:** Documentation + polish

**Total:** 16 days (buffer included)

---

## Next Steps After 2.1

Once uninstall is complete:
1. Move to Phase 2.2 (Testing Infrastructure)
2. Create test suites for optional features
3. Integrate tests into CI

---

**Status:** Ready to implement  
**Start Date:** November 4, 2025  
**Target Completion:** November 15, 2025
