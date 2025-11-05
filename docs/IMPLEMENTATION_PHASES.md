# Implementation Phases - Complete Roadmap

**Project:** Ubuntu Bootstrap - Module Uninstall System  
**Current Phase:** 2.1 (In Progress)  
**Status:** 43% Complete (3/7 modules)  
**Last Updated:** November 4, 2025

---

## Overview

Complete implementation roadmap for the module uninstall system, organized into sequential phases with clear acceptance criteria, time estimates, and quality gates.

---

## Phase 1: Foundation Infrastructure ✅ COMPLETE

**Status:** ✅ **COMPLETED** (November 3, 2025)  
**Duration:** 6 hours (estimated 8 hours)  
**Commit:** `2ea55e6` on `feature/module-uninstalls-batch2`

### Deliverables Completed

1. **Universal Test Framework** (`scripts/lib/test_framework.sh`)
   - 367 lines, 14 assertion types, 26 helper functions
   - Color-coded output (green/red/yellow)
   - Standardized test reporting
   - Reusable across all modules

2. **Common Utility Library** (`scripts/lib/common.sh`)
   - 173 lines, 9 utility functions
   - `apt_safe()` - Retry logic for transient failures
   - `backup_shell_file()` - Safe shell config backups
   - `remove_lines_from_file()` - Exact pattern cleanup
   - `confirm_action()` - User confirmation helper

3. **Module Implementations** (3/7 complete)
   - Utilities: 100% (install + uninstall + 25 tests)
   - VS Code: 100% (install + uninstall + 15 tests)
   - Node.js: 100% (install + uninstall + 19 tests)

4. **Makefile Integration**
   - `make test` - Run all test suites
   - `make test-module MODULE=<name>` - Test specific module
   - `make test-syntax` - Shellcheck validation
   - `make test-dry-run` - DRY_RUN mode tests
   - `make test-quick` - Fast validation

### Quality Metrics Achieved

- ✅ 58/58 tests passing (100% pass rate)
- ✅ Zero code duplication in completed modules
- ✅ All shell scripts pass shellcheck
- ✅ DRY_RUN mode tested and working
- ✅ FORCE mode tested and working
- ✅ Comprehensive documentation (BATCH_2_PLAN.md, PROGRESS_LOG.md)

### Lessons Learned

- Test framework investment paid off 3x over
- Common library eliminated ~200 lines of duplication
- DRY_RUN mode prevented all accidental deletions
- Pattern templates accelerate development exponentially

---

## Phase 2A: Python Module ⏳ NEXT

**Status:** ⏳ **READY TO START**  
**Estimated Duration:** 1 hour (faster with proven pattern)  
**Complexity:** 🟢 Low (similar to Node.js)

### Implementation Steps

#### Step 1: Implement Uninstall Function (20 min)

**File:** `scripts/dev-modules/python.sh`

```bash
# Add these functions after install_python()

is_python_installed() {
  # Check for pyenv directory
  if [[ -d "$HOME/.pyenv" ]]; then
    return 0
  fi
  return 1
}

backup_python_config() {
  local backup_dir="${1:-$(create_backup_dir "python")}"
  
  mkdir -p "$backup_dir"
  
  # Backup pyenv version if set
  if [[ -f "$HOME/.python-version" ]]; then
    cp "$HOME/.python-version" "$backup_dir/"
    log "[BACKUP] Saved .python-version"
  fi
  
  # List installed Python versions
  if [[ -d "$HOME/.pyenv/versions" ]]; then
    ls -1 "$HOME/.pyenv/versions" > "$backup_dir/installed_versions.txt" 2>/dev/null || true
    log "[BACKUP] Saved list of installed Python versions"
  fi
  
  # Backup shell configs
  backup_shell_file "$HOME/.bashrc" "$backup_dir"
  backup_shell_file "$HOME/.profile" "$backup_dir"
  
  log "[BACKUP] Backup created at: $backup_dir"
  echo "$backup_dir"
}

uninstall_python() {
  local dry_run="${DRY_RUN:-0}"
  local force="${FORCE:-0}"
  
  log "[UNINSTALL] Starting Python (pyenv) uninstall..."
  
  # Check if installed
  if ! is_python_installed; then
    log "[UNINSTALL] Python (pyenv) not installed, skipping."
    return 0
  fi
  
  # Confirm with user
  if [[ $force -eq 0 ]] && [[ $dry_run -eq 0 ]]; then
    echo ""
    echo "This will remove:"
    echo "  - ~/.pyenv directory (all installed Python versions)"
    echo "  - Python virtual environments (if any)"
    echo "  - pyenv configuration from shell configs"
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
    backup_dir=$(backup_python_config)
    log "[BACKUP] Backup created at: $backup_dir"
  else
    log "[DRY_RUN] Would create backup directory"
  fi
  
  # Remove pyenv directory
  if [[ -d "$HOME/.pyenv" ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove directory: $HOME/.pyenv"
    else
      log "[UNINSTALL] Removing $HOME/.pyenv..."
      rm -rf "$HOME/.pyenv"
    fi
  fi
  
  # Remove .python-version file
  if [[ -f "$HOME/.python-version" ]]; then
    if [[ $dry_run -eq 1 ]]; then
      log "[DRY_RUN] Would remove file: $HOME/.python-version"
    else
      log "[UNINSTALL] Removing $HOME/.python-version"
      rm -f "$HOME/.python-version"
    fi
  fi
  
  # Clean shell configs
  local shell_configs=("$HOME/.bashrc" "$HOME/.profile")
  local patterns=(
    "export PYENV_ROOT="
    "pyenv init"
    "# pyenv configuration"
  )
  
  for config in "${shell_configs[@]}"; do
    if [[ -f "$config" ]]; then
      for pattern in "${patterns[@]}"; do
        if grep -qF "$pattern" "$config" 2>/dev/null; then
          if [[ $dry_run -eq 1 ]]; then
            log "[DRY_RUN] Would remove pyenv lines from $config"
          else
            log "[UNINSTALL] Cleaning $config..."
            remove_lines_from_file "$config" "$pattern"
          fi
        fi
      done
    fi
  done
  
  log "[UNINSTALL] Python (pyenv) uninstall complete."
  log "Note: Restart your shell or run 'exec bash' to apply changes."
  return 0
}
```

#### Step 2: Create Test Suite (25 min)

**File:** `scripts/dev-modules/test_python.sh`

Create following test template:
- Syntax validation (shellcheck)
- Function existence (3 functions: is_, backup_, uninstall_)
- Detection when installed
- Detection when not installed  
- DRY_RUN mode doesn't change state
- FORCE flag accepted
- Backup function creates directory
- Shell cleanup patterns present
- Handles not-installed gracefully
- Verify pyenv patterns removed

#### Step 3: Validation (15 min)

```bash
# Test syntax
make test-syntax

# Test module
make test-module MODULE=python

# Verify all tests pass
# Expected: ~20 tests passing
```

#### Step 4: Commit

```bash
git add scripts/dev-modules/python.sh scripts/dev-modules/test_python.sh
git commit -m "feat(python): Add pyenv uninstall function with comprehensive tests

- Implement is_python_installed() detection
- Add backup_python_config() with version tracking
- Create uninstall_python() with shell cleanup
- Add 20 test cases covering all scenarios
- Support DRY_RUN and FORCE modes
- Clean PYENV_ROOT and pyenv init from shell configs"
```

### Acceptance Criteria

- ✅ All tests passing (target: 20/20)
- ✅ Shellcheck validation passes
- ✅ DRY_RUN mode tested and working
- ✅ Shell cleanup verified with exact patterns
- ✅ Backup creation tested
- ✅ Documentation in code comments

---

## Phase 2B: Rust Module ⏳ NEXT

**Status:** ⏳ **READY TO START**  
**Estimated Duration:** 1 hour  
**Complexity:** 🟢 Low (simplest of remaining modules)

### Implementation Steps

#### Step 1: Implement Uninstall Function (20 min)

**File:** `scripts/dev-modules/rust.sh`

Key implementation points:
- Use `rustup self-uninstall` command (built-in uninstaller)
- Clean `.cargo/env` sourcing from shell configs
- Remove `~/.cargo` and `~/.rustup` directories
- Simple PATH cleanup

#### Step 2: Create Test Suite (25 min)

**File:** `scripts/dev-modules/test_rust.sh`

Test cases (~15 tests):
- Syntax validation
- Function existence
- Rustup detection
- PATH cleanup verification
- DRY_RUN mode
- FORCE flag
- Backup creation
- Self-uninstall command handling

#### Step 3: Validation & Commit (15 min)

```bash
make test-module MODULE=rust
git commit -m "feat(rust): Add rustup uninstall function with tests"
```

### Acceptance Criteria

- ✅ All tests passing (target: 15/15)
- ✅ `rustup self-uninstall` properly invoked
- ✅ Shell cleanup working
- ✅ DRY_RUN mode tested

---

## Phase 2C: Go Module ⏳ PENDING

**Status:** ⏳ **PENDING** (after Rust)  
**Estimated Duration:** 1.5 hours  
**Complexity:** 🟡 Medium (requires sudo)

### Implementation Steps

#### Step 1: Implement Uninstall Function (30 min)

**File:** `scripts/dev-modules/go.sh`

Key implementation points:
- Remove `/usr/local/go` (requires sudo)
- Clean PATH and GOPATH from shell configs
- Optionally remove `~/go` directory (ask user)
- Handle sudo privilege escalation safely

#### Step 2: Create Test Suite (40 min)

**File:** `scripts/dev-modules/test_go.sh`

Test cases (~15 tests):
- Syntax validation
- Function existence
- Go detection (/usr/local/go)
- PATH/GOPATH cleanup
- Sudo handling (mock/dry-run)
- User directory handling (~/go)
- DRY_RUN mode
- FORCE flag

#### Step 3: Validation & Commit (20 min)

```bash
make test-module MODULE=go
git commit -m "feat(go): Add Go uninstall with sudo handling and tests"
```

### Acceptance Criteria

- ✅ All tests passing (target: 15/15)
- ✅ Sudo operations in DRY_RUN mode
- ✅ System directory removal working
- ✅ User directory prompt working

---

## Phase 2D: Docker Module ⏳ PENDING

**Status:** ⏳ **PENDING** (implement last - most complex)  
**Estimated Duration:** 3 hours  
**Complexity:** 🔴 High (services, groups, data safety)

### Implementation Steps

#### Step 1: Research & Design (30 min)

Document Docker installation artifacts:
- Services: `docker.service`, `docker.socket`, `containerd.service`
- Packages: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- Group membership: `docker` group
- Data directory: `/var/lib/docker` (images, containers, volumes)
- Configuration: `/etc/docker/daemon.json`

Design safety checks:
- Warn about running containers
- Require explicit confirmation for data deletion
- Document group removal needs logout

#### Step 2: Implement Uninstall Function (90 min)

**File:** `scripts/dev-modules/docker.sh`

Key implementation points:
```bash
uninstall_docker() {
  # 1. Check for running containers - WARN USER
  # 2. Stop services (docker.service, docker.socket)
  # 3. Remove user from docker group
  # 4. Remove packages (apt-get purge)
  # 5. ASK about /var/lib/docker removal (CRITICAL)
  # 6. Remove /etc/docker configuration
  # 7. Clean PATH if custom bins added
  
  # CRITICAL WARNINGS:
  # - Running containers will be stopped
  # - All images will be lost unless backed up
  # - All volumes will be lost unless backed up
  # - Group removal requires logout
}
```

#### Step 3: Create Test Suite (40 min)

**File:** `scripts/dev-modules/test_docker.sh`

Test cases (~20 tests):
- Syntax validation
- Function existence
- Service detection
- Group membership checks
- Package detection
- Running container detection
- Data directory handling
- DRY_RUN mode (critical for Docker)
- FORCE flag
- Warning messages present
- Backup creation

#### Step 4: Validation & Commit (20 min)

```bash
# IMPORTANT: Test with REAL Docker in DRY_RUN first
DRY_RUN=1 FORCE=1 source scripts/dev-modules/docker.sh && uninstall_docker

make test-module MODULE=docker
git commit -m "feat(docker): Add comprehensive Docker uninstall with safety checks"
```

### Acceptance Criteria

- ✅ All tests passing (target: 20/20)
- ✅ Service stop working
- ✅ Group removal working
- ✅ Package removal working
- ✅ Critical warnings displayed
- ✅ Data directory handling safe
- ✅ DRY_RUN mode thoroughly tested

### Safety Checklist

- [ ] Warn about running containers
- [ ] Require explicit data directory confirmation
- [ ] Document logout requirement for group
- [ ] Test DRY_RUN with real Docker installation
- [ ] Verify no data loss in DRY_RUN mode
- [ ] Test FORCE mode carefully

---

## Phase 3: Central Orchestrator ⏳ PENDING

**Status:** ⏳ **PENDING** (after all modules complete)  
**Estimated Duration:** 2 hours  
**Complexity:** 🟡 Medium

### Implementation Steps

#### Step 1: Create Orchestrator Script (60 min)

**File:** `scripts/uninstall_bootstrap.sh`

Features:
- Interactive menu (select modules to uninstall)
- `--all` flag (uninstall everything with confirmation)
- Specific module selection (`./uninstall_bootstrap.sh docker nodejs`)
- `--help` output
- DRY_RUN and FORCE mode support
- Safe uninstall order (reverse of install dependencies)
- Progress reporting
- Backup location reporting

Structure:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source all modules
for module in dev-modules/*.sh; do source "$module"; done
for module in optional-features/*.sh; do source "$module"; done

# Functions:
# - show_help()
# - interactive_menu()
# - uninstall_all()
# - uninstall_batch()
# - main()

# Uninstall order (safe reverse order):
# 1. Docker (no dependencies)
# 2. Go (no dependencies)
# 3. Rust (no dependencies)
# 4. Python (no dependencies)
# 5. Node.js (no dependencies)
# 6. VS Code (might use Node.js)
# 7. Utilities (used by everything)
```

#### Step 2: Create Integration Tests (40 min)

**File:** `scripts/test_uninstall_integration.sh`

Test scenarios:
- Help output works
- DRY_RUN all modules
- Specific module selection
- Invalid module handling
- FORCE mode works
- Backup creation across modules

#### Step 3: Validation & Commit (20 min)

```bash
# Test help
bash scripts/uninstall_bootstrap.sh --help

# Test dry-run all
DRY_RUN=1 bash scripts/uninstall_bootstrap.sh --all

# Run integration tests
bash scripts/test_uninstall_integration.sh

git commit -m "feat(orchestrator): Add central uninstall system with interactive mode"
```

### Acceptance Criteria

- ✅ Interactive menu working
- ✅ --all flag working with confirmation
- ✅ Specific module selection working
- ✅ Help output clear and comprehensive
- ✅ DRY_RUN mode working
- ✅ Progress reporting working
- ✅ Integration tests passing

---

## Phase 4: Makefile Integration ⏳ PENDING

**Status:** ⏳ **PENDING**  
**Estimated Duration:** 30 minutes  
**Complexity:** 🟢 Low

### Implementation

**File:** `Makefile`

Add targets:
```makefile
# Uninstall targets
.PHONY: uninstall uninstall-all uninstall-dry uninstall-module

uninstall: ## Interactive uninstall of development tools
	@bash "$(DIR)/scripts/uninstall_bootstrap.sh"

uninstall-all: ## Uninstall all development tools (with confirmation)
	@bash "$(DIR)/scripts/uninstall_bootstrap.sh" --all

uninstall-dry: ## Preview uninstall without making changes
	@DRY_RUN=1 bash "$(DIR)/scripts/uninstall_bootstrap.sh" --all

uninstall-module: ## Uninstall specific module (Usage: make uninstall-module MODULE=docker)
	@bash "$(DIR)/scripts/uninstall_bootstrap.sh" $(MODULE)
```

### Validation

```bash
make uninstall --dry-run  # Should show help
make help | grep uninstall  # Should show new targets
DRY_RUN=1 make uninstall-all  # Should preview
```

### Acceptance Criteria

- ✅ All targets working
- ✅ Help text updated
- ✅ Consistent with existing patterns
- ✅ Documented in Makefile comments

---

## Phase 5: Documentation ⏳ PENDING

**Status:** ⏳ **PENDING**  
**Estimated Duration:** 1 hour  
**Complexity:** 🟢 Low

### Task 5A: Create UNINSTALL.md (30 min)

**File:** `docs/UNINSTALL.md`

Sections:
1. Quick Start (TL;DR commands)
2. Interactive Mode
3. Uninstall All
4. Uninstall Specific Modules
5. DRY_RUN Mode (preview)
6. FORCE Mode (skip confirmations)
7. Backup Location
8. Per-Module Instructions
9. Troubleshooting
10. FAQ

### Task 5B: Update README.md (15 min)

**File:** `README.md`

Add section:
```markdown
## Uninstalling

Remove specific tools:
```bash
make uninstall
# or
bash scripts/uninstall_bootstrap.sh docker nodejs
```

Remove everything:
```bash
make uninstall-all
```

Preview changes (safe):
```bash
make uninstall-dry
```

See [UNINSTALL.md](docs/UNINSTALL.md) for detailed instructions.

**Note:** All configurations are backed up to `~/.local/share/ubuntu-bootstrap/backups/` before removal.
```

### Task 5C: Update RELEASE_NOTES.md (15 min)

**File:** `RELEASE_NOTES.md`

Document Phase 2.1 completion:
- New uninstall system for all dev-modules
- Universal test framework
- Common utility library
- DRY_RUN mode for safe previews
- Comprehensive test coverage (100+ tests)

### Acceptance Criteria

- ✅ UNINSTALL.md comprehensive and clear
- ✅ README.md updated with quick start
- ✅ RELEASE_NOTES.md documents changes
- ✅ All documentation links working
- ✅ Examples tested and accurate

---

## Phase 6: Final Validation & Release ⏳ PENDING

**Status:** ⏳ **PENDING**  
**Estimated Duration:** 1 hour  
**Complexity:** 🟡 Medium

### Validation Checklist

#### Code Quality
- [ ] All 7 modules have complete uninstall functions
- [ ] All test suites passing (target: 100+ tests)
- [ ] Shellcheck passes on all scripts
- [ ] No TODOs or FIXMEs in production code
- [ ] DRY_RUN mode tested on all modules
- [ ] FORCE mode tested on all modules

#### Functionality
- [ ] Central orchestrator working (interactive, --all, specific)
- [ ] Makefile targets working
- [ ] Integration tests passing
- [ ] Backup creation verified
- [ ] Shell cleanup verified

#### Documentation
- [ ] UNINSTALL.md complete and accurate
- [ ] README.md updated
- [ ] RELEASE_NOTES.md updated
- [ ] All documentation links working
- [ ] Code comments clear

#### Git Workflow
- [ ] All changes committed
- [ ] Commit messages follow convention
- [ ] Git status clean (no untracked files)
- [ ] Branch up to date with origin

### Merge Process

```bash
# Final test
make test
# Expected: All tests passing (100+ tests)

# Check git status
git status
# Expected: Clean working tree

# Checkout main
git checkout main
git pull origin main

# Merge feature branch
git merge feature/module-uninstalls-batch2 --no-ff

# Tag release
git tag -a v2.0.0 -m "Release v2.0.0: Complete uninstall system

- Add uninstall functions for all 7 dev-modules
- Implement universal test framework (14 assertions)
- Create common utility library (9 functions)
- Add central uninstall orchestrator
- Achieve 100% test coverage
- Total: 100+ tests passing"

# Push everything
git push origin main
git push origin v2.0.0

# Clean up feature branch (optional)
git branch -d feature/module-uninstalls-batch2
git push origin --delete feature/module-uninstalls-batch2
```

### Acceptance Criteria

- ✅ All 7 modules 100% complete
- ✅ 100+ tests passing
- ✅ All documentation complete
- ✅ Merged to main
- ✅ Release tagged
- ✅ All changes pushed

---

## Timeline Summary

| Phase | Duration | Complexity | Status |
|-------|----------|------------|--------|
| 1. Foundation | 6h | Medium | ✅ Complete |
| 2A. Python | 1h | Low | ⏳ Next |
| 2B. Rust | 1h | Low | ⏳ Next |
| 2C. Go | 1.5h | Medium | ⏳ Pending |
| 2D. Docker | 3h | High | ⏳ Pending |
| 3. Orchestrator | 2h | Medium | ⏳ Pending |
| 4. Makefile | 0.5h | Low | ⏳ Pending |
| 5. Documentation | 1h | Low | ⏳ Pending |
| 6. Validation | 1h | Medium | ⏳ Pending |
| **TOTAL** | **17h** | | **35% Done** |

**Remaining:** ~11 hours (2-3 sessions)

---

## Success Metrics

### Code Coverage
- Target: 100+ tests across all modules
- Current: 58 tests (utilities, vscode, nodejs)
- Remaining: ~50 tests (python, rust, go, docker, integration)

### Test Pass Rate
- Target: 100%
- Current: 100% (58/58)
- Critical: Maintain 100% throughout

### Documentation Coverage
- Target: All modules documented
- Current: 3/7 modules
- Create: UNINSTALL.md

### Quality Gates
- All shellcheck passes
- All tests passing
- DRY_RUN mode working
- No untracked files
- Clean commit history

---

## Risk Management

### High-Risk Areas

1. **Docker Uninstall** 🔴
   - Multiple services
   - Data directory (/var/lib/docker)
   - Group membership changes
   - **Mitigation:** Implement last, thorough DRY_RUN testing

2. **Shell Config Cleanup** 🟡
   - Pattern matching errors could break shells
   - **Mitigation:** Exact patterns only, backup first, verify removal

3. **Sudo Operations** 🟡
   - Go module requires sudo
   - Docker module requires sudo
   - **Mitigation:** Test in DRY_RUN, clear user warnings

### Low-Risk Areas

1. **Python/Rust Modules** 🟢
   - Similar to completed Node.js module
   - Proven patterns apply directly

2. **Test Framework** 🟢
   - Already complete and working
   - Just apply to new modules

3. **Documentation** 🟢
   - Straightforward writing
   - Examples from existing modules

---

## Quality Assurance Process

### Before Each Commit

1. Run syntax validation: `make test-syntax`
2. Run module tests: `make test-module MODULE=<name>`
3. Run full suite: `make test`
4. Review changes: `git diff`
5. Verify commit message follows convention

### Before Each Phase Completion

1. Review acceptance criteria
2. Run integration tests
3. Update documentation
4. Get peer review (if applicable)
5. Tag milestone in git

### Before Final Merge

1. Complete validation checklist
2. Run all tests (100+ target)
3. Verify all documentation
4. Clean git status
5. Review all commits
6. Test on clean system (if possible)

---

## Notes for Future Phases

### Phase 3 Considerations (Orchestrator)
- Consider dependency order (uninstall in reverse)
- Add progress bars for multiple modules
- Implement rollback on error
- Log all actions to file

### Phase 4 Considerations (Makefile)
- Keep consistent with existing targets
- Add to help output
- Consider tab completion helpers

### Phase 5 Considerations (Documentation)
- Include animated GIFs/screenshots (optional)
- Add FAQ from user questions
- Cross-reference related docs

### Phase 6 Considerations (Release)
- Test on Ubuntu 22.04 and 24.04
- Verify on fresh install
- Consider beta testers
- Prepare announcement

---

## Appendix A: Command Reference

### Development Commands

```bash
# Test specific module
make test-module MODULE=python

# Test all modules
make test

# Test syntax only
make test-syntax

# Preview uninstall (safe)
DRY_RUN=1 source scripts/dev-modules/python.sh && uninstall_python

# Force uninstall (skip prompts)
FORCE=1 source scripts/dev-modules/python.sh && uninstall_python

# Run integration tests
bash scripts/test_uninstall_integration.sh
```

### Git Commands

```bash
# Status check
git status
git log --oneline -10

# Commit
git add <files>
git commit -m "feat(module): Description"

# Push
git push origin feature/module-uninstalls-batch2

# Merge
git checkout main
git merge feature/module-uninstalls-batch2 --no-ff
git tag v2.0.0
git push origin main --tags
```

---

## Appendix B: Pattern Templates

See `docs/BATCH_2_PLAN.md` and `docs/PHASE_2_1_UNINSTALL_GUIDE.md` for detailed implementation patterns.

---

**Document Version:** 1.0  
**Last Updated:** November 4, 2025  
**Status:** Living document (update as phases progress)
