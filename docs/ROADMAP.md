# Ubuntu Bootstrap — Strategic Roadmap v1.1.0

**Document Version:** 1.1.0  
**Last Updated:** November 1, 2025  
**Status:** Planning Phase  
**Current Version:** v1.0.2

---

## Executive Summary

Ubuntu Bootstrap has reached production stability with v1.0.2. This roadmap outlines the strategic direction for the next 6-12 months, prioritizing **user safety, testing infrastructure, and extensibility** while maintaining the project's core principle of simplicity and reliability.

**Key Strategic Pillars:**
1. **Safety First:** Complete rollback/uninstall capability before adding features
2. **Test Everything:** Comprehensive automated testing to prevent regressions
3. **User Empowerment:** Better configuration, backup, and recovery options
4. **Community Growth:** Plugin architecture and multi-distro support

---

## Current State Analysis

### Strengths (What's Working Well)

**Architecture:**
- ✅ Modular design with clear separation (`dev-modules/`, `optional-features/`, `hardware/`)
- ✅ Robust error handling (`set -euo pipefail`, retry logic, lock management)
- ✅ Security-first approach (no hardcoded credentials, path validation, mktemp)
- ✅ Idempotent operations (safe to run multiple times)

**User Experience:**
- ✅ Comprehensive documentation (10+ guides covering different aspects)
- ✅ Dry-run mode for risk-free preview
- ✅ Hardware auto-detection with fallback profiles
- ✅ Per-script logging with timestamps
- ✅ Clear error messages with remediation hints

**Developer Experience:**
- ✅ CI/CD with GitHub Actions (shellcheck, shfmt, verify)
- ✅ Makefile with intuitive targets (`make run`, `make verify`, `make optional`)
- ✅ Release automation with tags
- ✅ Deployment checklist for quality assurance

### Critical Gaps (What Needs Immediate Attention)

**1. Incomplete Rollback Capability** ⚠️ HIGH PRIORITY
- **Problem:** All 7 dev-modules have uninstall stubs returning "not yet implemented"
- **Risk:** Users cannot cleanly remove components if issues arise
- **Impact:** Reduces confidence in trying new features
- **Dependencies:** Blocks safe experimentation and testing
- **Example:** After installing Docker, users can't easily remove it to free disk space

**2. Limited Test Coverage** ⚠️ HIGH PRIORITY
- **Problem:** Only ProtonVPN has automated tests; 90% of codebase untested
- **Risk:** Regressions can slip into production undetected
- **Impact:** Manual testing is time-consuming and error-prone
- **Dependencies:** Must have tests before adding complexity
- **Example:** A change to apt_safe could break all package installations silently

**3. No Pre-Bootstrap Backup** ⚠️ MEDIUM PRIORITY
- **Problem:** Bootstrap modifies system without creating restore point
- **Risk:** Users can't easily revert if bootstrap causes issues
- **Impact:** Fear of running bootstrap on production machines
- **Dependencies:** Requires TimeShift integration and snapshot logic
- **Example:** Bootstrap changes .bashrc; user wants original back

**4. Environment Variable Configuration Only** ⚠️ MEDIUM PRIORITY
- **Problem:** 15+ configuration options via env vars; hard to manage
- **Risk:** Users forget settings between runs; no persistence
- **Impact:** Difficult to reproduce setups or share configs with teams
- **Dependencies:** Config file parser needed
- **Example:** User wants same setup on laptop and desktop but must re-type flags

**5. Ubuntu 24.04 Only** ⚠️ LOW PRIORITY
- **Problem:** Many potential users run Debian, Fedora, Arch, or older Ubuntu
- **Risk:** Limits user base growth
- **Impact:** Can't leverage network effects or community contributions
- **Dependencies:** Requires package manager abstraction
- **Example:** Debian user wants same experience but can't use bootstrap

---

## Phase 2: Foundation Hardening (Weeks 1-6)

**Goal:** Build the safety net that enables confident experimentation and rapid iteration

### 2.1 Uninstall/Rollback Implementation (Weeks 1-2)

**Priority:** 🔴 CRITICAL  
**Effort:** 2-3 days per module × 7 modules = 14-21 days (parallelizable)  
**Owner:** Core maintainer

#### Deep Analysis: Why This Matters

**User Perspective:**
- "I tried Docker but it uses too much disk space; I want to remove it cleanly"
- "VS Code slows down my system; I need to uninstall it properly"
- "I installed everything to test, now I only want Python—how do I clean up?"

**Technical Perspective:**
- Uninstall is more complex than install (config files, user data, PATH cleanup)
- Different tools have different uninstall procedures (apt vs. installer scripts)
- Must handle partial installations (what if install failed midway?)

**Risk Analysis:**
- **High Risk:** Destructive operations (removing $HOME directories)
- **Medium Risk:** Leaving orphaned configs/PATH entries
- **Low Risk:** Not removing optional packages (user can apt autoremove)

#### Implementation Strategy

**Phase 2.1.1: Design Uninstall API (Day 1)**

Create consistent interface across all modules:

```bash
# Standard uninstall function signature
uninstall_<module>() {
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"  # Skip confirmations
  
  # 1. Detect if installed
  if ! is_<module>_installed; then
    log "[UNINSTALL] <Module> not installed, skipping"
    return 0
  fi
  
  # 2. Confirm with user (unless FORCE=1)
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    read -p "Remove <Module>? This will delete configs. [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
  fi
  
  # 3. Backup configs before removal
  backup_<module>_config
  
  # 4. Stop services
  stop_<module>_services
  
  # 5. Remove packages
  remove_<module>_packages
  
  # 6. Clean user data (with caution)
  clean_<module>_data
  
  # 7. Remove PATH entries
  clean_<module>_path
  
  # 8. Verify removal
  verify_<module>_removed
  
  log "[UNINSTALL] <Module> removed successfully"
}
```

**Phase 2.1.2: Implement Each Module (Days 2-14)**

Order of implementation (by complexity):

1. **utilities.sh** (easiest, just apt remove)
2. **vscode.sh** (apt remove + repo cleanup)
3. **nodejs.sh** (remove nvm directory, clean .bashrc)
4. **python.sh** (remove pyenv directory, clean .bashrc)
5. **rust.sh** (rustup self uninstall, clean PATH)
6. **go.sh** (remove /usr/local/go, clean PATH)
7. **docker.sh** (hardest: remove packages, group, configs, images)

**Per-Module Checklist:**

For each module, implement:
- [ ] `is_<module>_installed()` detection function
- [ ] `backup_<module>_config()` to save user data
- [ ] `stop_<module>_services()` if applicable
- [ ] `remove_<module>_packages()` for apt/snap/manual installs
- [ ] `clean_<module>_data()` for ~/.config, ~/.local, ~/.cache
- [ ] `clean_<module>_path()` for .bashrc, .profile modifications
- [ ] `verify_<module>_removed()` post-removal checks
- [ ] Manual test: install → uninstall → verify clean
- [ ] Automated test: `test_<module>_uninstall.sh`

**Phase 2.1.3: Central Orchestrator (Days 15-17)**

Create `scripts/uninstall_bootstrap.sh`:

```bash
#!/usr/bin/env bash
# Central uninstall orchestrator
# Usage: ./uninstall_bootstrap.sh [module1 module2 ...]
#        ./uninstall_bootstrap.sh --all

set -euo pipefail

# Source all dev-modules for their uninstall functions
for module in scripts/dev-modules/*.sh; do
  source "$module"
done

# Interactive mode: prompt for each module
interactive_uninstall() {
  echo "Select modules to uninstall (space-separated numbers):"
  echo "1) Docker"
  echo "2) Node.js"
  echo "3) Python"
  echo "4) Rust"
  echo "5) Go"
  echo "6) VS Code"
  echo "7) Dev Utilities"
  echo "8) All of the above"
  read -p "Choice: " choices
  # ... implement selection logic
}

# Batch mode: uninstall specified modules
batch_uninstall() {
  local modules=("$@")
  for module in "${modules[@]}"; do
    uninstall_"${module}"
  done
}

main() {
  if [[ $# -eq 0 ]]; then
    interactive_uninstall
  elif [[ "$1" == "--all" ]]; then
    # Reverse order of installation
    uninstall_dev_utilities
    uninstall_vscode
    uninstall_go
    uninstall_rust
    uninstall_python
    uninstall_nodejs
    uninstall_docker
  else
    batch_uninstall "$@"
  fi
}

main "$@"
```

**Phase 2.1.4: Integration & Testing (Days 18-21)**

- [ ] Add `--uninstall` flag to `run_bootstrap.sh`
- [ ] Add `make uninstall` target to Makefile
- [ ] Update all optional features with uninstall functions
- [ ] Create `docs/UNINSTALL.md` with comprehensive guide
- [ ] Test full cycle: fresh install → bootstrap → uninstall → verify clean
- [ ] Document edge cases (partial installs, modified configs)

#### Success Criteria

- ✅ All 7 dev-modules have working `uninstall_*()` functions
- ✅ Uninstall preserves user data in `backups/<timestamp>/`
- ✅ Uninstall returns exit 0 if module not installed
- ✅ Automated tests verify clean removal
- ✅ Documentation covers common scenarios and edge cases
- ✅ No "not yet implemented" messages remain in codebase

---

### 2.2 Testing Infrastructure (Weeks 3-4)

**Priority:** 🔴 CRITICAL  
**Effort:** 3-4 days  
**Owner:** Core maintainer + community contributors

#### Deep Analysis: Testing Strategy

**Current Gap:**
- Only `test_protonvpn.sh` exists (134 lines, well-structured)
- No integration tests for dev-modules
- No regression tests for core bootstrap scripts
- Manual verification required after changes

**Testing Philosophy:**

1. **Unit Tests** (module-level)
   - Test each function in isolation
   - Mock external dependencies (apt, curl, systemctl)
   - Fast execution (<1s per test)

2. **Integration Tests** (module-level)
   - Test full install → verify → uninstall cycle
   - Use actual system commands (slower but realistic)
   - Run in Docker container for isolation

3. **End-to-End Tests** (system-level)
   - Full bootstrap run in clean environment
   - Verify all components work together
   - Run in CI on every commit

4. **Smoke Tests** (sanity checks)
   - Quick validation that basics work
   - Run before releases and after major changes
   - DRY_RUN mode tests (syntax and logic paths)

#### Implementation Plan

**Week 3: Test Framework & Dev-Module Tests**

Day 1-2: Create test framework
```bash
# scripts/lib/test_framework.sh
assert_installed() { ... }
assert_not_installed() { ... }
assert_file_exists() { ... }
assert_command_succeeds() { ... }
assert_command_fails() { ... }
run_test_suite() { ... }
```

Day 3-5: Implement dev-module tests
```bash
# scripts/dev-modules/test_docker.sh
test_docker_install() { ... }
test_docker_verify() { ... }
test_docker_uninstall() { ... }
test_docker_idempotent() { ... }
```

Replicate for: nodejs, python, rust, go, vscode, utilities

**Week 4: Optional Feature Tests & CI Integration**

Day 1-3: Create optional feature tests
```bash
# scripts/optional-features/test_brave.sh
test_brave_repo_added() { ... }
test_brave_installed() { ... }
test_brave_launches() { ... }
test_brave_uninstall() { ... }
```

Replicate for: vlc, libreoffice, timeshift

Day 4-5: CI integration
- Update `.github/workflows/ci.yml` to run test suite
- Add matrix testing (Ubuntu 22.04, 24.04)
- Add test result reporting and badges
- Create `make test` and `make test-quick` targets

#### Test Coverage Goals

| Component | Target Coverage | Priority |
|-----------|----------------|----------|
| Core bootstrap (run_bootstrap.sh) | 80% | HIGH |
| Dev-modules | 90% | HIGH |
| Optional features | 80% | MEDIUM |
| Hardware detection | 70% | MEDIUM |
| Utility functions | 95% | HIGH |

#### Success Criteria

- ✅ Test framework with assertion helpers implemented
- ✅ All 7 dev-modules have test files with ≥4 tests each
- ✅ All 5 optional features have test files
- ✅ CI runs tests on every PR
- ✅ `make test` completes in <5 minutes locally
- ✅ Test coverage badge shows >75%

---

### 2.3 Enhanced CI/CD (Week 5)

**Priority:** 🟡 MEDIUM  
**Effort:** 2-3 days  
**Owner:** Core maintainer

#### Current CI Limitations

**`.github/workflows/ci.yml`:**
- Runs shellcheck (good)
- Runs shfmt (good)
- But doesn't test actual functionality
- No DRY_RUN smoke tests
- No multi-version testing

**`.github/workflows/verify.yml`:**
- Only runs `scripts/verify.sh`
- Doesn't test install/uninstall
- Single Ubuntu version (24.04)

#### Enhancement Plan

**Day 1: DRY_RUN Smoke Tests**

Add to ci.yml:
```yaml
smoke-test:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Run DRY_RUN bootstrap
      run: |
        DRY_RUN=1 bash scripts/run_bootstrap.sh
        # Should exit 0 even in dry-run
    
    - name: Run DRY_RUN with skips
      run: |
        DRY_RUN=1 bash scripts/run_bootstrap.sh --skip-script=40
        DRY_RUN=1 bash scripts/run_bootstrap.sh --skip-script=50
```

**Day 2: Matrix Testing**

```yaml
test-matrix:
  strategy:
    matrix:
      ubuntu-version: ['22.04', '24.04']
  runs-on: ubuntu-${{ matrix.ubuntu-version }}
  steps:
    - name: Full bootstrap test
      run: |
        # In Docker container for isolation
        docker run -v $(pwd):/bootstrap \
          ubuntu:${{ matrix.ubuntu-version }} \
          bash /bootstrap/scripts/run_bootstrap.sh
```

**Day 3: Test Suite Integration & Reporting**

```yaml
integration-test:
  runs-on: ubuntu-24.04
  steps:
    - name: Run test suite
      run: make test
    
    - name: Upload test results
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: test-results/
    
    - name: Comment PR with results
      uses: actions/github-script@v6
      with:
        script: |
          // Post test summary to PR
```

#### Additional Enhancements

- **Pre-commit hooks:** shellcheck, shfmt on modified .sh files
- **Release automation:** Generate changelog from commits
- **Security scanning:** shellcheck with security rules
- **Performance tracking:** Time each script, warn on regressions
- **Dependency updates:** Dependabot for GitHub Actions

#### Success Criteria

- ✅ DRY_RUN smoke test catches syntax errors
- ✅ Matrix testing validates Ubuntu 22.04 and 24.04
- ✅ Test suite runs in CI and reports results
- ✅ Coverage badge updates automatically
- ✅ Pre-commit hooks prevent bad commits

---

## Phase 3: User Empowerment (Weeks 7-12)

**Goal:** Give users control, confidence, and recovery options

### 3.1 Configuration Management (Weeks 7-8)

**Priority:** 🟡 MEDIUM  
**Effort:** 3-4 days

#### Problem Statement

**Current state:**
```bash
# User must remember and type this every time:
DRY_RUN=1 LOG_DIR=/custom/logs HARDWARE_PROFILE=thinkpad-t14 \
  bash scripts/run_bootstrap.sh --skip-script=40 --skip-script=50
```

**Desired state:**
```bash
# Create config once:
$ cat .ubuntu-bootstrap.yaml
bootstrap:
  skip_scripts: [40, 50]
  hardware_profile: thinkpad-t14
  log_dir: /custom/logs

dev_tools:
  docker: false
  nodejs: true
  python: true

# Then just run:
$ bash scripts/run_bootstrap.sh --config .ubuntu-bootstrap.yaml
```

#### Design Decisions

**Config Format:** YAML vs. TOML vs. JSON

| Format | Pros | Cons | Decision |
|--------|------|------|----------|
| YAML | Human-readable, comments | Indentation-sensitive | ✅ **Choose** |
| TOML | Explicit, simple | Less common | ❌ |
| JSON | Universal, simple parsing | No comments, verbose | ❌ |

**Config Location Priority:**
1. CLI: `--config /path/to/config.yaml` (highest)
2. Local: `./.ubuntu-bootstrap.yaml`
3. User: `~/.config/ubuntu-bootstrap/config.yaml`
4. System: `/etc/ubuntu-bootstrap/config.yaml` (lowest)

**Environment Variable Override:**
- Config file values can be overridden by env vars
- Precedence: CLI flags > ENV vars > Config file > Defaults

#### Implementation Plan

**Day 1: Schema Definition**

```yaml
# .ubuntu-bootstrap.schema.yaml
version: "1.0"  # Config schema version

bootstrap:
  dry_run: false
  strict_mode: false
  skip_scripts: []  # List of script numbers to skip
  hardware_profile: auto  # auto | thinkpad-t14 | hp-laptop-15 | generic
  log_dir: null  # null = default to logs/<timestamp>
  auto_snapshot: false  # Create TimeShift snapshot before run

dev_tools:
  enabled: true  # Master switch
  docker: true
  nodejs: true
  python: true
  rust: false
  go: false
  vscode: true
  utilities: true

optional_features:
  enabled: false  # Master switch
  brave: false
  protonvpn: false
  vlc: false
  libreoffice: false
  timeshift: false

custom:
  apt_packages: []  # Additional packages to install
  pip_packages: []
  npm_packages: []
  vscode_extensions: []

network:
  retry_count: 3
  connect_timeout: 10
  apt_retries: 6

advanced:
  skip_network_check: false
  force_hardware_profile: false
  parallel_installs: false  # Future: run independent modules in parallel
```

**Day 2: Config Parser**

```bash
# scripts/lib/config_parser.sh
parse_config() {
  local config_file="$1"
  
  # Use yq if available, fallback to python
  if command -v yq >/dev/null 2>&1; then
    parse_with_yq "$config_file"
  elif command -v python3 >/dev/null 2>&1; then
    parse_with_python "$config_file"
  else
    log "ERROR: Config parsing requires yq or python3"
    return 1
  fi
}

validate_config() {
  local config_file="$1"
  # Check schema version compatibility
  # Validate required fields
  # Warn about deprecated fields
  # Suggest migrations
}

merge_config_with_env() {
  # ENV vars override config file
  # Export standardized variable names
}
```

**Day 3-4: Integration & Generation**

- [ ] Update `run_bootstrap.sh` to accept `--config` flag
- [ ] Add config file discovery logic
- [ ] Implement `--generate-config` to create starter file
- [ ] Add `--validate-config` to check config without running
- [ ] Create `docs/CONFIGURATION.md` with examples
- [ ] Add config version migration helper

#### Success Criteria

- ✅ Config file successfully controls all bootstrap behavior
- ✅ ENV vars properly override config values
- ✅ `--generate-config` creates valid starter config
- ✅ Validation catches common errors with helpful messages
- ✅ Config works with both local and system-wide placement

---

### 3.2 Backup & Restore (Weeks 9-10)

**Priority:** 🟠 HIGH  
**Effort:** 2-3 days

#### User Stories

1. **Safety Net:** "Before running bootstrap, I want automatic backup of my current configs"
2. **System Snapshot:** "I want a full system snapshot before bootstrap modifies packages"
3. **Selective Restore:** "I want to restore just .bashrc, not the entire system"
4. **Rollback:** "Bootstrap broke my system; I need one-command restore"

#### Implementation Strategy

**Phase 3.2.1: Config Backup (Day 1)**

```bash
# scripts/lib/backup.sh
backup_configs() {
  local backup_dir="$HOME/.local/share/ubuntu-bootstrap/backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  
  # Files to backup before modification
  local files_to_backup=(
    "$HOME/.bashrc"
    "$HOME/.profile"
    "$HOME/.bash_profile"
    "$HOME/.gitconfig"
    "/etc/apt/sources.list.d/"  # Repo additions
    "/etc/systemd/system/"  # Service overrides
  )
  
  for file in "${files_to_backup[@]}"; do
    if [[ -e "$file" ]]; then
      cp -a "$file" "$backup_dir/"
      log "Backed up: $file"
    fi
  done
  
  # Save package list
  dpkg --get-selections > "$backup_dir/packages.list"
  apt-mark showmanual > "$backup_dir/manual-packages.list"
  
  echo "$backup_dir" > "$HOME/.ubuntu-bootstrap-last-backup"
  log "Backup complete: $backup_dir"
}
```

**Phase 3.2.2: TimeShift Integration (Day 2)**

```bash
# scripts/lib/snapshot.sh
create_snapshot() {
  if ! command -v timeshift >/dev/null 2>&1; then
    log "TimeShift not installed; skipping snapshot"
    return 0
  fi
  
  local snapshot_name="ubuntu-bootstrap-$(date +%Y%m%d-%H%M%S)"
  local snapshot_desc="Pre-bootstrap snapshot for rollback"
  
  log "Creating system snapshot: $snapshot_name"
  sudo timeshift --create --comments "$snapshot_desc" --tags D
  
  log "Snapshot created. Restore with: sudo timeshift --restore"
}

check_snapshot_available() {
  if command -v timeshift >/dev/null 2>&1; then
    local snapshot_count=$(sudo timeshift --list | grep -c "ubuntu-bootstrap" || true)
    if (( snapshot_count > 0 )); then
      log "Found $snapshot_count ubuntu-bootstrap snapshots"
      return 0
    fi
  fi
  return 1
}
```

**Phase 3.2.3: Restore Functionality (Day 3)**

```bash
# scripts/restore_from_backup.sh
#!/usr/bin/env bash
# Restore configs from most recent backup
set -euo pipefail

restore_configs() {
  local backup_dir="$1"
  
  if [[ ! -d "$backup_dir" ]]; then
    log "ERROR: Backup directory not found: $backup_dir"
    exit 1
  fi
  
  log "Restoring configs from: $backup_dir"
  
  # Confirm with user
  read -p "This will overwrite current configs. Continue? [y/N] " -n 1 -r
  echo
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
  
  # Restore files
  for file in "$backup_dir"/*; do
    local basename=$(basename "$file")
    local target=""
    
    case "$basename" in
      .bashrc|.profile|.bash_profile|.gitconfig)
        target="$HOME/$basename"
        ;;
      packages.list|manual-packages.list)
        continue  # Handled separately
        ;;
      *)
        log "Skipping unknown file: $basename"
        continue
        ;;
    esac
    
    if [[ -n "$target" ]]; then
      cp -a "$file" "$target"
      log "Restored: $target"
    fi
  done
  
  log "Config restore complete"
}

# Main entry point
main() {
  if [[ -f "$HOME/.ubuntu-bootstrap-last-backup" ]]; then
    local last_backup=$(cat "$HOME/.ubuntu-bootstrap-last-backup")
    restore_configs "$last_backup"
  else
    log "No backup found. Specify backup directory:"
    read -p "Backup dir: " backup_dir
    restore_configs "$backup_dir"
  fi
}

main "$@"
```

**Phase 3.2.4: Integration (Day 4)**

- [ ] Add `--auto-snapshot` flag to run_bootstrap.sh
- [ ] Add `AUTO_SNAPSHOT=1` environment variable support
- [ ] Prompt user before first run: "Create snapshot? [Y/n]"
- [ ] Add `make restore` target
- [ ] Create `docs/ROLLBACK.md` with recovery procedures
- [ ] Test full cycle: backup → bootstrap → restore → verify

#### Success Criteria

- ✅ Configs automatically backed up before modification
- ✅ TimeShift snapshot created if available
- ✅ Restore script successfully reverts changes
- ✅ User can choose snapshot or config-only restore
- ✅ Rollback guide tested and validated

---

### 3.3 Web Dashboard (Weeks 11-12) [OPTIONAL]

**Priority:** 🟢 LOW  
**Effort:** 5-7 days  
**Owner:** Community contributor ideal

This is marked optional because it's a nice-to-have, not essential for core functionality. Can be deferred to Phase 4 or implemented as a plugin.

**Key Features:**
- Real-time log viewing
- Feature selection UI
- Progress indicators
- System health dashboard

**Tech Stack:** Python Flask + htmx + Tailwind CSS
**Deliverable:** Runs with `make dashboard`, opens browser to localhost:8080

---

## Phase 4: Expansion (Months 4-6)

### 4.1 Multi-Distro Support (Weeks 13-16)

**Priority:** 🟠 HIGH (for growth)  
**Effort:** 7-10 days

#### Target Distributions

**Tier 1 (Must Support):**
- Ubuntu 22.04, 24.04 ✅ (already supported)
- Debian 11 (Bullseye), 12 (Bookworm)

**Tier 2 (Should Support):**
- Fedora 39, 40
- Pop!_OS 22.04

**Tier 3 (Nice to Have):**
- Arch Linux
- Linux Mint
- Elementary OS

#### Package Manager Abstraction

```bash
# scripts/lib/pkg_manager.sh
detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo "unknown"
  fi
}

pkg_update() {
  case "$PKG_MANAGER" in
    apt) sudo apt-get update ;;
    dnf) sudo dnf check-update ;;
    pacman) sudo pacman -Sy ;;
  esac
}

pkg_install() {
  local packages=("$@")
  case "$PKG_MANAGER" in
    apt) apt_safe install -y "${packages[@]}" ;;
    dnf) sudo dnf install -y "${packages[@]}" ;;
    pacman) sudo pacman -S --noconfirm "${packages[@]}" ;;
  esac
}

pkg_remove() {
  local packages=("$@")
  case "$PKG_MANAGER" in
    apt) sudo apt-get remove -y "${packages[@]}" ;;
    dnf) sudo dnf remove -y "${packages[@]}" ;;
    pacman) sudo pacman -R --noconfirm "${packages[@]}" ;;
  esac
}
```

#### Distro-Specific Profiles

```
distros/
├── ubuntu/
│   ├── 22.04/
│   │   └── overrides.sh
│   └── 24.04/
│       └── overrides.sh
├── debian/
│   ├── 11/
│   │   └── overrides.sh
│   └── 12/
│       └── overrides.sh
├── fedora/
│   └── 40/
│       └── overrides.sh
└── arch/
    └── overrides.sh
```

---

### 4.2 Plugin Architecture (Weeks 17-20)

**Priority:** 🟡 MEDIUM  
**Effort:** 5-7 days

#### Plugin API Design

```bash
# plugin_template.sh
#!/usr/bin/env bash
# Plugin: Example Custom Tool
# Version: 1.0.0
# Author: community
# Description: Installs example custom tool

PLUGIN_NAME="example"
PLUGIN_VERSION="1.0.0"
PLUGIN_REQUIRES=("curl" "git")  # Dependencies
PLUGIN_CONFLICTS=("other-plugin")  # Conflicting plugins

# Hook: pre_install
# Called before any installation
plugin_pre_install() {
  log "[PLUGIN:$PLUGIN_NAME] Pre-install checks"
  # Validate system requirements
}

# Hook: install
# Main installation logic
plugin_install() {
  log "[PLUGIN:$PLUGIN_NAME] Installing..."
  # Installation steps
}

# Hook: post_install
# Called after installation
plugin_post_install() {
  log "[PLUGIN:$PLUGIN_NAME] Post-install configuration"
  # Configure tool
}

# Hook: verify
# Verify installation
plugin_verify() {
  if command -v example-tool >/dev/null 2>&1; then
    log "[PLUGIN:$PLUGIN_NAME] ✓ Verified"
    return 0
  else
    log "[PLUGIN:$PLUGIN_NAME] ✗ Verification failed"
    return 1
  fi
}

# Hook: uninstall
# Remove plugin
plugin_uninstall() {
  log "[PLUGIN:$PLUGIN_NAME] Uninstalling..."
  # Cleanup steps
}
```

#### Plugin Discovery & Management

```bash
# scripts/plugin_manager.sh
list_plugins() {
  # Local plugins
  find plugins/ -name "*.sh" -type f
  
  # User plugins
  find ~/.config/ubuntu-bootstrap/plugins/ -name "*.sh" -type f
}

install_plugin() {
  local plugin_name="$1"
  local plugin_file=$(find_plugin "$plugin_name")
  
  source "$plugin_file"
  plugin_pre_install
  plugin_install
  plugin_post_install
  plugin_verify
}

# Plugin registry (community plugins)
search_plugin_registry() {
  curl -s https://raw.githubusercontent.com/T-Green-hub/ubuntu-bootstrap-plugins/main/registry.json |
    jq -r ".plugins[] | select(.name | contains(\"$1\"))"
}
```

---

## Risk Management

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Uninstall removes wrong files | Medium | Critical | Double validation, dry-run mode, backups |
| Tests fail in CI but pass locally | Medium | High | Containerized testing, matrix testing |
| Config parser introduces bugs | Low | Medium | Schema validation, extensive tests |
| Multi-distro increases complexity | High | Medium | Package manager abstraction, distro profiles |
| Plugin API changes break plugins | Medium | Low | Semantic versioning, deprecation warnings |

### Resource Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Solo maintainer burnout | Medium | Critical | Document well, engage community, modular design |
| Testing takes too long in CI | Medium | Medium | Parallel jobs, test caching, selective tests |
| Storage for backups/logs | Low | Low | Cleanup old backups, configurable retention |

### User Impact Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking changes confuse users | Medium | High | Deprecation warnings, migration guides, changelog |
| Documentation becomes outdated | High | Medium | Documentation tests, regular reviews |
| Config migration issues | Low | Medium | Automated migration, validation, warnings |

---

## Success Metrics

### Phase 2 Metrics

**Quantitative:**
- Zero "not yet implemented" messages in codebase
- Test coverage >75% for all modules
- CI passes on 2+ Ubuntu versions
- Average uninstall time <2 minutes

**Qualitative:**
- Users report confidence in trying features
- Community contributors submit uninstall PRs
- GitHub issues about "how to remove X" decrease

### Phase 3 Metrics

**Quantitative:**
- Config file adoption >50% of users
- Pre-bootstrap backups created automatically
- Restore success rate >95%

**Qualitative:**
- Users share config files in discussions
- Fewer "bootstrap broke my system" reports
- Documentation praise increases

### Phase 4 Metrics

**Quantitative:**
- Support 3+ distros (Ubuntu, Debian, Fedora)
- 10+ community plugins available
- Non-Ubuntu users >20% of user base

**Qualitative:**
- Cross-distro success stories
- Plugin ecosystem growth
- Community contributions increase

---

## Timeline Summary

```
Week 1-2:   Uninstall/Rollback (CRITICAL)
Week 3-4:   Testing Infrastructure (CRITICAL)
Week 5:     Enhanced CI/CD (MEDIUM)
Week 6:     Buffer/Documentation
Week 7-8:   Configuration Management (MEDIUM)
Week 9-10:  Backup & Restore (HIGH)
Week 11-12: Web Dashboard (OPTIONAL - can skip)
Week 13-16: Multi-Distro Support (HIGH)
Week 17-20: Plugin Architecture (MEDIUM)
```

**Total:** ~20 weeks (5 months) for full Phase 2-4 implementation

**Minimum Viable:** Phases 2.1, 2.2, 3.2 = ~6 weeks (critical path)

---

## Community Engagement Strategy

### How to Get Community Help

**Good First Issues:**
- Implement uninstall for a single dev-module
- Write test for optional feature (brave, vlc, libreoffice)
- Add hardware profile for new laptop model
- Translate documentation to other languages
- Create example plugin for popular tool

**Medium Difficulty:**
- Implement distro-specific profile (Debian, Fedora)
- Create web dashboard component
- Add performance profiling
- Improve error messages

**Advanced:**
- Design plugin API architecture
- Implement parallel installations
- Create comprehensive test framework

### Documentation for Contributors

Create `docs/CONTRIBUTING.md`:
- Code style guide
- Testing requirements
- PR checklist
- Review process
- Community code of conduct

---

## Open Questions to Resolve

1. **Uninstall Confirmation:** Should we require `FORCE=1` to skip confirmations, or use `--force` flag?
2. **Test Isolation:** Docker containers or system tests? Tradeoff: speed vs. realism
3. **Config Format:** YAML requires yq/python; should we support multiple formats?
4. **Backup Retention:** Auto-delete backups older than X days? Default retention policy?
5. **Plugin Security:** How to verify community plugins are safe? Code review? Sandbox?
6. **Multi-Distro Priority:** Focus on Debian first (closest to Ubuntu) or Fedora (different package manager)?
7. **Breaking Changes:** When is it OK to break backward compatibility? Semver policy?

---

## Conclusion

This roadmap prioritizes **safety and testing** before expansion. The critical path is:

1. **Uninstall/Rollback** → Users can safely experiment
2. **Testing Infrastructure** → Catch regressions early
3. **Backup & Restore** → Recovery path for issues

Everything else builds on this foundation. The modular architecture allows community contributions without core rewrites.

**Next Actions:**
1. Review this roadmap with stakeholders
2. Create GitHub project board with these phases
3. Label issues as "phase-2", "phase-3", "phase-4"
4. Start implementation of Phase 2.1 (Uninstall)
5. Document progress in monthly updates

---

**Document Control:**
- **Version:** 1.1.0
- **Last Updated:** November 1, 2025
- **Next Review:** December 1, 2025
- **Owner:** T-Green-hub
- **Status:** Planning → Implementation (Phase 2.1 start)
