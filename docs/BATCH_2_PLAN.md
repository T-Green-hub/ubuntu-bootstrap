# Phase 1 - Batch 2: Implementation Plan

**Phase:** Foundation - Remaining Module Uninstalls  
**Batch:** 2 of 3  
**Date:** November 4-6, 2025  
**Status:** ⏳ READY TO START

---

## Overview

Implement uninstall functions and test suites for the remaining 6 dev-modules using the proven pattern from utilities.sh.

**Proven Pattern (from Batch 1):**
- Detection function: `is_<module>_installed()`
- Backup function: `backup_<module>_config()`
- Uninstall function: `uninstall_<module>()`
- Test suite: `test_<module>.sh`
- DRY_RUN and FORCE support

---

## Implementation Sequence

### Session 1: VS Code & Node.js (4 hours)

#### Task 1.1: VS Code Uninstall (2 hours)
**File:** `scripts/dev-modules/vscode.sh`

**Subtasks:**
1. [ ] Read current vscode.sh to understand installation
2. [ ] Implement `is_vscode_installed()` - Check for `code` command
3. [ ] Implement `backup_vscode_config()` - Backup `~/.config/Code/User/settings.json`
4. [ ] Implement `uninstall_vscode()`:
   - Remove apt package `code`
   - Remove `/etc/apt/sources.list.d/vscode.list`
   - Remove `/etc/apt/trusted.gpg.d/microsoft.gpg`
   - Optionally remove `~/.vscode` and `~/.config/Code` (ask user)
5. [ ] Create `test_vscode.sh` using utilities template
6. [ ] Run: `make test-module MODULE=vscode`

**Commands to implement:**
```bash
# Detection
command -v code >/dev/null 2>&1

# Removal
apt_safe remove -y code
sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /etc/apt/trusted.gpg.d/microsoft.gpg
sudo apt-get update
```

**Test cases (minimum 6):**
1. Syntax validation
2. Function existence (3 functions)
3. Detection when installed
4. Detection when not installed
5. Dry-run doesn't remove
6. Force flag works

#### Task 1.2: Node.js Uninstall (2 hours)
**File:** `scripts/dev-modules/nodejs.sh`

**Subtasks:**
1. [ ] Read current nodejs.sh to understand nvm installation
2. [ ] Implement `is_nodejs_installed()` - Check for `~/.nvm` directory
3. [ ] Implement `backup_nodejs_config()` - Backup `~/.npmrc` if exists
4. [ ] Implement `uninstall_nodejs()`:
   - Remove `~/.nvm` directory
   - Clean `.bashrc` of nvm lines (3 lines to remove)
   - Clean `.profile` of nvm lines
   - Optionally remove `~/.npm` cache
5. [ ] Create `test_nodejs.sh`
6. [ ] Run: `make test-module MODULE=nodejs`

**Shell config cleanup pattern:**
```bash
# Create temp file without nvm lines
grep -v 'NVM_DIR' ~/.bashrc > ~/.bashrc.tmp
grep -v 'nvm.sh' ~/.bashrc.tmp > ~/.bashrc.new
mv ~/.bashrc.new ~/.bashrc
rm ~/.bashrc.tmp

# Or use sed in-place editing
sed -i '/NVM_DIR/d' ~/.bashrc
sed -i '/nvm\.sh/d' ~/.bashrc
sed -i '/bash_completion/d' ~/.bashrc
```

---

### Session 2: Python & Rust (3.5 hours)

#### Task 2.1: Python Uninstall (2 hours)
**File:** `scripts/dev-modules/python.sh`

**Subtasks:**
1. [ ] Read current python.sh to understand pyenv installation
2. [ ] Implement `is_python_installed()` - Check for `~/.pyenv` directory
3. [ ] Implement `backup_python_config()` - Backup pyenv settings
4. [ ] Implement `uninstall_pyenv()`:
   - Warn about virtual environments
   - Remove `~/.pyenv` directory
   - Clean `.bashrc` of pyenv lines (3 lines)
   - Clean `.profile` of pyenv lines
5. [ ] Create `test_python.sh`
6. [ ] Run: `make test-module MODULE=python`

**Virtual environment warning:**
```bash
if [ -d "$HOME/.pyenv/versions" ]; then
  echo "WARNING: Found Python virtual environments:"
  ls "$HOME/.pyenv/versions"
  echo "These will be removed. Continue? [y/N]"
fi
```

#### Task 2.2: Rust Uninstall (1.5 hours)
**File:** `scripts/dev-modules/rust.sh`

**Subtasks:**
1. [ ] Read current rust.sh to understand rustup installation
2. [ ] Implement `is_rust_installed()` - Check for `rustup` command
3. [ ] Implement `backup_rust_config()` - Backup `~/.cargo/config.toml`
4. [ ] Implement `uninstall_rust()`:
   - Run `rustup self uninstall -y`
   - Clean `.profile` of cargo bin PATH
   - Verify `~/.cargo` and `~/.rustup` removed
5. [ ] Create `test_rust.sh`
6. [ ] Run: `make test-module MODULE=rust`

**Rust-specific:**
```bash
# Rust has built-in uninstaller
if command -v rustup >/dev/null 2>&1; then
  rustup self uninstall -y
fi

# Clean PATH
sed -i '/\.cargo\/bin/d' ~/.profile
```

---

### Session 3: Go & Docker (4.5 hours)

#### Task 3.1: Go Uninstall (1.5 hours)
**File:** `scripts/dev-modules/go.sh`

**Subtasks:**
1. [ ] Read current go.sh to understand installation
2. [ ] Implement `is_go_installed()` - Check for `/usr/local/go`
3. [ ] Implement `backup_go_config()` - Backup GOPATH if set
4. [ ] Implement `uninstall_go()`:
   - Remove `/usr/local/go` (needs sudo)
   - Clean `.profile` of Go PATH entries
   - Remove GOPATH from environment
5. [ ] Create `test_go.sh`
6. [ ] Run: `make test-module MODULE=go`

**System-wide removal:**
```bash
# Go installed system-wide
if [ -d "/usr/local/go" ]; then
  sudo rm -rf /usr/local/go
fi

# Clean PATH
sed -i '/\/usr\/local\/go\/bin/d' ~/.profile
sed -i '/go\/bin/d' ~/.profile
```

#### Task 3.2: Docker Uninstall (3 hours) ⚠️ COMPLEX
**File:** `scripts/dev-modules/docker.sh`

**Subtasks:**
1. [ ] Read current docker.sh to understand full installation
2. [ ] Implement `is_docker_installed()` - Check for docker command + service
3. [ ] Implement `backup_docker_config()` - Backup `/etc/docker/daemon.json`
4. [ ] Implement `uninstall_docker()`:
   - **CRITICAL:** Warn about data loss (images, containers, volumes)
   - Stop docker service
   - Remove user from docker group
   - Remove packages (docker-ce, docker-ce-cli, containerd.io, etc.)
   - Clean `/var/lib/docker` (ask user, default NO)
   - Remove `/etc/apt/sources.list.d/docker.list`
   - Remove GPG key
5. [ ] Create `test_docker.sh`
6. [ ] Run: `make test-module MODULE=docker`

**Docker-specific safety:**
```bash
uninstall_docker(){
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  # CRITICAL WARNING
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "                    ⚠️  WARNING  ⚠️"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "This will remove Docker and potentially:"
  echo "  - All Docker images"
  echo "  - All Docker containers"
  echo "  - All Docker volumes"
  echo "  - All Docker networks"
  echo ""
  
  # List what exists
  if command -v docker >/dev/null 2>&1; then
    echo "Current Docker resources:"
    docker images --format "  Images: {{.Repository}}:{{.Tag}}" 2>/dev/null | head -5
    docker ps -a --format "  Containers: {{.Names}}" 2>/dev/null | head -5
    docker volume ls --format "  Volumes: {{.Name}}" 2>/dev/null | head -5
    echo ""
  fi
  
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    read -p "Remove Docker data (/var/lib/docker)? [y/N] " -n 1 -r
    echo ""
    local remove_data=0
    [[ $REPLY =~ ^[Yy]$ ]] && remove_data=1
  fi
  
  # Stop services first
  if systemctl is-active --quiet docker 2>/dev/null; then
    sudo systemctl stop docker
    sudo systemctl stop docker.socket
  fi
  
  # Remove user from docker group
  if groups "$USER" | grep -q docker; then
    sudo deluser "$USER" docker
  fi
  
  # Remove packages
  local docker_pkgs=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
  )
  
  for pkg in "${docker_pkgs[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      apt_safe remove -y "$pkg"
    fi
  done
  
  # Clean data if requested
  if [[ $remove_data -eq 1 ]]; then
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
  fi
  
  # Clean repo
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.gpg
  sudo apt-get update
}
```

---

## Testing Strategy

### Per-Module Tests (Minimum)
Each module must have:
1. ✅ Syntax validation
2. ✅ Function existence checks (3-4 functions)
3. ✅ Detection logic (installed vs not installed)
4. ✅ Dry-run mode verification
5. ✅ Backup function testing
6. ✅ Force flag handling

### Integration Tests
After all modules complete:
```bash
# Test all modules
make test

# Test dry-run for all
DRY_RUN=1 make test

# Test syntax
make test-syntax
```

---

## Safety Checklist

### Before Each Uninstall Implementation
- [ ] Read installation code to understand what was added
- [ ] Identify all files/directories created
- [ ] Identify all shell config modifications
- [ ] Identify all system packages installed
- [ ] Plan backup strategy

### During Implementation
- [ ] Implement DRY_RUN mode first
- [ ] Test dry-run before real removal
- [ ] Add confirmation prompts for destructive actions
- [ ] Back up configs before modification
- [ ] Log all actions

### After Implementation
- [ ] Test on system with module installed
- [ ] Test on system without module installed
- [ ] Test dry-run mode
- [ ] Test force mode
- [ ] Verify clean removal (no leftover files)

---

## Shell Config Cleanup Patterns

### Safe sed Pattern
```bash
# Backup first
cp ~/.bashrc ~/.bashrc.bak-$(date +%Y%m%d-%H%M%S)

# Remove specific lines
sed -i '/PATTERN_TO_REMOVE/d' ~/.bashrc

# Remove range of lines (if known)
sed -i '/START_PATTERN/,/END_PATTERN/d' ~/.bashrc

# Verify changes
diff ~/.bashrc.bak-* ~/.bashrc
```

### Alternative: grep -v Pattern
```bash
# Create new file without unwanted lines
grep -v 'PATTERN_TO_REMOVE' ~/.bashrc > ~/.bashrc.new
mv ~/.bashrc.new ~/.bashrc
```

### Recommended Approach
```bash
# 1. Create backup
backup_shell_config() {
  local backup_dir="$1"
  cp ~/.bashrc "$backup_dir/bashrc"
  cp ~/.profile "$backup_dir/profile"
}

# 2. Remove lines with exact patterns
clean_shell_config() {
  local pattern="$1"
  sed -i.bak "/$pattern/d" ~/.bashrc
  sed -i.bak "/$pattern/d" ~/.profile
}

# 3. Verify removal
verify_shell_config() {
  local pattern="$1"
  if grep -q "$pattern" ~/.bashrc ~/.profile 2>/dev/null; then
    return 1
  fi
  return 0
}
```

---

## File Structure Reference

```
scripts/
├── dev-modules/
│   ├── utilities.sh          ✅ COMPLETE (Batch 1)
│   ├── test_utilities.sh     ✅ COMPLETE (Batch 1)
│   ├── vscode.sh             ⏳ TODO (Session 1)
│   ├── test_vscode.sh        ⏳ TODO (Session 1)
│   ├── nodejs.sh             ⏳ TODO (Session 1)
│   ├── test_nodejs.sh        ⏳ TODO (Session 1)
│   ├── python.sh             ⏳ TODO (Session 2)
│   ├── test_python.sh        ⏳ TODO (Session 2)
│   ├── rust.sh               ⏳ TODO (Session 2)
│   ├── test_rust.sh          ⏳ TODO (Session 2)
│   ├── go.sh                 ⏳ TODO (Session 3)
│   ├── test_go.sh            ⏳ TODO (Session 3)
│   ├── docker.sh             ⏳ TODO (Session 3)
│   └── test_docker.sh        ⏳ TODO (Session 3)
└── lib/
    └── test_framework.sh     ✅ COMPLETE (Batch 1)
```

---

## Common Patterns Reference

### Detection Function Template
```bash
is_<module>_installed(){
  # Method 1: Check for command
  command -v <command> >/dev/null 2>&1 && return 0
  
  # Method 2: Check for directory
  [[ -d "$HOME/.<module>" ]] && return 0
  
  # Method 3: Check for package
  dpkg -s <package> >/dev/null 2>&1 && return 0
  
  return 1
}
```

### Backup Function Template
```bash
backup_<module>_config(){
  local backup_dir="${1:-$HOME/.local/share/ubuntu-bootstrap/backups/<module>-$(date +%Y%m%d-%H%M%S)}"
  
  mkdir -p "$backup_dir"
  
  # Backup configs
  [[ -f "$HOME/.<module>rc" ]] && cp "$HOME/.<module>rc" "$backup_dir/"
  [[ -d "$HOME/.<module>" ]] && cp -r "$HOME/.<module>" "$backup_dir/"
  
  log "[BACKUP] Config backup directory: $backup_dir"
  echo "$backup_dir"
}
```

---

## Validation Checklist

After completing Batch 2:

### Code Quality
- [ ] All 6 modules have `is_*_installed()` functions
- [ ] All 6 modules have `backup_*_config()` functions
- [ ] All 6 modules have `uninstall_*()` functions
- [ ] All 6 modules have test suites
- [ ] Zero "not yet implemented" messages
- [ ] All code passes `make test-syntax`

### Functionality
- [ ] All tests pass: `make test`
- [ ] Dry-run works for all modules
- [ ] Force mode works for all modules
- [ ] Backups created correctly
- [ ] Shell configs cleaned properly
- [ ] No errors in CI

### Documentation
- [ ] Inline comments for complex logic
- [ ] Function docstrings
- [ ] Test cases documented
- [ ] Known issues noted

---

## Time Tracking

| Session | Modules | Estimated | Status |
|---------|---------|-----------|--------|
| 1 | VS Code, Node.js | 4h | ⏳ TODO |
| 2 | Python, Rust | 3.5h | ⏳ TODO |
| 3 | Go, Docker | 4.5h | ⏳ TODO |
| **Total** | **6 modules** | **12h** | **0% Complete** |

---

## Next Steps After Batch 2

1. **Create central orchestrator** (`scripts/uninstall_bootstrap.sh`)
2. **Create pre-flight checks** (`scripts/preflight_check.sh`)
3. **Update documentation** (UNINSTALL.md, README.md)
4. **Prepare v1.1.0 release**

---

**Status:** Ready to begin Session 1  
**First Task:** Implement VS Code uninstall  
**Command:** Start with `git checkout -b feature/module-uninstalls-batch2`
