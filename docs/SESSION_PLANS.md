# Session-Based Execution Plans

**Project:** Ubuntu Bootstrap - Module Uninstall System  
**Planning Date:** November 4, 2025  
**Total Estimated Time:** 11 hours remaining  
**Sessions Needed:** 3-4 sessions

---

## Session 1: Python + Rust Modules

**Duration:** 2-3 hours  
**Date:** TBD  
**Goal:** Complete 2 easiest remaining modules  
**Complexity:** 🟢 Low

### Pre-Session Checklist
- [ ] Review Node.js implementation (proven pattern)
- [ ] Have shell configs backed up manually (safety)
- [ ] Terminal ready with `make test-module` command
- [ ] Fresh coffee ☕

### Execution Plan

#### Part 1: Python Module (1 hour)

**Minutes 0-20: Implement uninstall function**
```bash
# Edit scripts/dev-modules/python.sh
# Add: is_python_installed(), backup_python_config(), uninstall_python()
# Copy pattern from nodejs.sh, replace NVM → PYENV
```

**Minutes 20-45: Create test suite**
```bash
# Create scripts/dev-modules/test_python.sh
# Copy template from test_nodejs.sh
# Adapt tests for pyenv instead of nvm
# Target: 20 tests
```

**Minutes 45-60: Validate and commit**
```bash
make test-syntax
make test-module MODULE=python
# Expect: 20/20 tests passing

git add scripts/dev-modules/python.sh scripts/dev-modules/test_python.sh
git commit -m "feat(python): Add pyenv uninstall function with comprehensive tests"
```

#### Part 2: Rust Module (1 hour)

**Minutes 60-80: Implement uninstall function**
```bash
# Edit scripts/dev-modules/rust.sh
# Add: is_rust_installed(), backup_rust_config(), uninstall_rust()
# Key: Use 'rustup self-uninstall' command
# Simpler than Python - just PATH cleanup
```

**Minutes 80-105: Create test suite**
```bash
# Create scripts/dev-modules/test_rust.sh
# Copy template from test_python.sh
# Adapt for rustup
# Target: 15 tests
```

**Minutes 105-120: Validate and commit**
```bash
make test-module MODULE=rust
# Expect: 15/15 tests passing

git add scripts/dev-modules/rust.sh scripts/dev-modules/test_rust.sh
git commit -m "feat(rust): Add rustup uninstall function with tests"
```

#### Part 3: Validation (30 minutes)

**Minutes 120-135: Full test suite**
```bash
make test
# Expect: 90+ tests passing (utilities 25, vscode 14, nodejs 19, python 20, rust 15+)
```

**Minutes 135-150: Push and celebrate**
```bash
git push origin feature/module-uninstalls-batch2

# Update progress
# 5/7 modules complete (71%)
# ~85 tests passing
```

### Session 1 Acceptance Criteria

- ✅ Python module 100% complete
- ✅ Rust module 100% complete
- ✅ All tests passing (target: 90+)
- ✅ Changes committed and pushed
- ✅ No regressions in existing modules

### What Could Go Wrong

**Problem:** Shell cleanup patterns don't match exactly  
**Solution:** Use exact strings from installation code  
**Prevention:** Test with DRY_RUN first

**Problem:** Tests fail unexpectedly  
**Solution:** Check shellcheck first, then debug failing assertion  
**Prevention:** Copy working test template exactly

**Problem:** Forgot to source common.sh  
**Solution:** Add at top of file: `source "$(dirname "$0")/../lib/common.sh"`  
**Prevention:** Check nodejs.sh for correct sourcing pattern

---

## Session 2: Go + Docker Modules

**Duration:** 4-5 hours  
**Date:** TBD  
**Goal:** Complete remaining 2 complex modules  
**Complexity:** 🟡 Medium to 🔴 High

### Pre-Session Checklist
- [ ] Review sudo operations in existing code
- [ ] Read Docker installation code thoroughly
- [ ] Have Docker test environment ready
- [ ] Set aside uninterrupted time block

### Execution Plan

#### Part 1: Go Module (1.5 hours)

**Minutes 0-30: Implement uninstall function**
```bash
# Edit scripts/dev-modules/go.sh
# Add: is_go_installed(), backup_go_config(), uninstall_go()
# Key challenge: Requires sudo for /usr/local/go
# Handle ~/go directory (ask user)
```

**Minutes 30-70: Create test suite**
```bash
# Create scripts/dev-modules/test_go.sh
# Test sudo operations (must use DRY_RUN mocking)
# Test user directory prompts
# Target: 15 tests
```

**Minutes 70-90: Validate and commit**
```bash
make test-module MODULE=go
# Expect: 15/15 tests passing

git add scripts/dev-modules/go.sh scripts/dev-modules/test_go.sh
git commit -m "feat(go): Add Go uninstall with sudo handling and tests"
```

#### Part 2: Docker Module (3 hours) 🔴 COMPLEX

**Minutes 90-120: Research and design (30 min)**
```bash
# Document all Docker artifacts:
# - Services: docker.service, docker.socket, containerd.service
# - Packages: docker-ce, docker-ce-cli, containerd.io, plugins
# - Group: docker
# - Data: /var/lib/docker (CRITICAL)
# - Config: /etc/docker/daemon.json

# Design safety checks in detail
```

**Minutes 120-210: Implement uninstall function (90 min)**
```bash
# Edit scripts/dev-modules/docker.sh
# Add: is_docker_installed(), backup_docker_config(), uninstall_docker()

# Critical sections:
# 1. Detect running containers
# 2. Stop all services
# 3. Remove from docker group
# 4. Remove packages
# 5. ASK about /var/lib/docker (EXPLICIT CONFIRMATION)
# 6. Remove config files

# SAFETY FIRST:
# - Multiple confirmation prompts
# - Clear warnings about data loss
# - Document logout requirement
```

**Minutes 210-250: Create test suite (40 min)**
```bash
# Create scripts/dev-modules/test_docker.sh
# Test service detection
# Test group membership
# Test package detection
# Test warning messages
# Test data directory handling
# Target: 20 tests
```

**Minutes 250-270: Thorough validation (20 min)**
```bash
# CRITICAL: Test with real Docker first
DRY_RUN=1 FORCE=1 source scripts/dev-modules/docker.sh && uninstall_docker
# Read all output carefully

# Then run test suite
make test-module MODULE=docker
# Expect: 20/20 tests passing
```

**Minutes 270-300: Commit and full validation (30 min)**
```bash
git add scripts/dev-modules/docker.sh scripts/dev-modules/test_docker.sh
git commit -m "feat(docker): Add comprehensive Docker uninstall with safety checks

- Detect and warn about running containers
- Stop all Docker services
- Remove from docker group (requires logout)
- Remove all packages
- Critical confirmation for /var/lib/docker data
- Comprehensive safety warnings
- 20 test cases covering all scenarios"

# Full test suite
make test
# Expect: 110+ tests passing (all 7 modules)
```

### Session 2 Acceptance Criteria

- ✅ Go module 100% complete
- ✅ Docker module 100% complete with safety checks
- ✅ All tests passing (target: 110+)
- ✅ DRY_RUN tested on real Docker installation
- ✅ All 7 modules complete
- ✅ Changes committed and pushed

### Docker Safety Checklist

- [ ] Warn about running containers
- [ ] Require explicit /var/lib/docker confirmation
- [ ] Document logout requirement for group removal
- [ ] Test DRY_RUN with real Docker installation
- [ ] Verify no data loss in DRY_RUN mode
- [ ] Multiple confirmation prompts
- [ ] Clear output messages

### What Could Go Wrong

**Problem:** Docker has running containers during test  
**Solution:** Stop containers first or skip real uninstall test  
**Prevention:** Use DRY_RUN mode for all development testing

**Problem:** Sudo password prompt during automated tests  
**Solution:** Mock sudo in tests, use DRY_RUN  
**Prevention:** Design tests to not require actual sudo

**Problem:** /var/lib/docker is huge, takes long to analyze  
**Solution:** Skip size check, just confirm with user  
**Prevention:** Make clear this is user's responsibility

---

## Session 3: Orchestrator + Integration

**Duration:** 3-4 hours  
**Date:** TBD  
**Goal:** Central orchestrator, integration tests, Makefile  
**Complexity:** 🟡 Medium

### Pre-Session Checklist
- [ ] All 7 modules complete and tested
- [ ] Review orchestrator design in PHASE_2_1_UNINSTALL_GUIDE.md
- [ ] Plan interactive menu structure

### Execution Plan

#### Part 1: Central Orchestrator (2 hours)

**Minutes 0-60: Create orchestrator script**
```bash
# Create scripts/uninstall_bootstrap.sh

# Implement:
# - show_help() function
# - interactive_menu() with module selection
# - uninstall_all() with confirmation
# - uninstall_batch() for specific modules
# - Safe uninstall order (reverse of dependencies)
# - Progress reporting
# - main() entry point

# Source all modules:
for module in dev-modules/*.sh; do source "$module"; done
```

**Minutes 60-100: Create integration tests**
```bash
# Create scripts/test_uninstall_integration.sh

# Test:
# - Help output
# - DRY_RUN all modules
# - Specific module selection
# - Invalid module handling
# - FORCE mode
# - Backup creation
# - Error handling
```

**Minutes 100-120: Validate orchestrator**
```bash
# Test help
bash scripts/uninstall_bootstrap.sh --help

# Test dry-run all
DRY_RUN=1 bash scripts/uninstall_bootstrap.sh --all

# Run integration tests
bash scripts/test_uninstall_integration.sh
# Expect: All scenarios passing

chmod +x scripts/uninstall_bootstrap.sh
git add scripts/uninstall_bootstrap.sh scripts/test_uninstall_integration.sh
git commit -m "feat(orchestrator): Add central uninstall system with interactive mode"
```

#### Part 2: Makefile Integration (30 minutes)

**Minutes 120-135: Add Makefile targets**
```bash
# Edit Makefile
# Add:
# - uninstall: Interactive mode
# - uninstall-all: Remove everything
# - uninstall-dry: Preview mode
# - uninstall-module: Specific module
```

**Minutes 135-150: Test Makefile targets**
```bash
make help | grep uninstall
DRY_RUN=1 make uninstall-all
make uninstall-module MODULE=utilities DRY_RUN=1

git add Makefile
git commit -m "feat(makefile): Add uninstall targets for all modules"
```

#### Part 3: Final Validation (1-1.5 hours)

**Minutes 150-180: Full test suite**
```bash
# Run everything
make test
# Expect: 110+ tests passing

# Test orchestrator
make uninstall --dry-run  # Interactive
DRY_RUN=1 make uninstall-all  # Full uninstall preview

# Test specific modules
make uninstall-module MODULE=docker DRY_RUN=1
make uninstall-module MODULE=python DRY_RUN=1
```

**Minutes 180-210: Git cleanup and push**
```bash
# Check status
git status
# Should be clean

# Check all commits
git log --oneline -15

# Push everything
git push origin feature/module-uninstalls-batch2

# Celebrate! 🎉
```

### Session 3 Acceptance Criteria

- ✅ Central orchestrator working
- ✅ Interactive menu functional
- ✅ --all flag working
- ✅ Specific module selection working
- ✅ Integration tests passing
- ✅ Makefile targets working
- ✅ All changes committed and pushed

---

## Session 4: Documentation + Release

**Duration:** 2 hours  
**Date:** TBD  
**Goal:** Complete documentation, merge, release  
**Complexity:** 🟢 Low

### Pre-Session Checklist
- [ ] All code complete and tested
- [ ] All commits pushed
- [ ] Feature branch up to date

### Execution Plan

#### Part 1: Documentation (1 hour)

**Minutes 0-30: Create UNINSTALL.md**
```bash
# Create docs/UNINSTALL.md

# Sections:
# 1. Quick Start
# 2. Interactive Mode
# 3. Uninstall All
# 4. Specific Modules
# 5. DRY_RUN Mode
# 6. FORCE Mode
# 7. Backup Location
# 8. Per-Module Details
# 9. Troubleshooting
# 10. FAQ

# Copy examples from existing docs
# Test all commands shown
```

**Minutes 30-45: Update README.md**
```bash
# Edit README.md
# Add "Uninstalling" section
# Include quick examples
# Link to UNINSTALL.md
```

**Minutes 45-60: Update RELEASE_NOTES.md**
```bash
# Edit RELEASE_NOTES.md
# Document v2.0.0 changes:
# - Complete uninstall system
# - Universal test framework
# - 100+ tests
# - Common utility library
# - DRY_RUN safety mode
```

**Minutes 60-65: Commit documentation**
```bash
git add docs/UNINSTALL.md README.md RELEASE_NOTES.md
git commit -m "docs: Add comprehensive uninstall documentation

- Create UNINSTALL.md with full guide
- Update README.md with uninstall section
- Document v2.0.0 changes in RELEASE_NOTES.md"

git push origin feature/module-uninstalls-batch2
```

#### Part 2: Final Validation (30 minutes)

**Minutes 65-80: Quality gates**
```bash
# Run all tests
make test
# Expected: 110+ tests passing, 100% pass rate

# Check shellcheck
make test-syntax
# Expected: All pass

# Verify git status
git status
# Expected: Clean working tree

# Review all commits
git log --oneline --graph feature/module-uninstalls-batch2
```

**Minutes 80-95: Documentation verification**
```bash
# Check all links in docs
# Test all command examples
# Read through UNINSTALL.md
# Verify README.md formatting
# Check RELEASE_NOTES.md accuracy
```

#### Part 3: Merge and Release (30 minutes)

**Minutes 95-105: Prepare for merge**
```bash
# Checkout main
git checkout main
git pull origin main

# Check for conflicts
git merge feature/module-uninstalls-batch2 --no-ff --no-commit
# Resolve any conflicts (shouldn't be any)
```

**Minutes 105-115: Merge and tag**
```bash
# Complete merge
git merge --continue  # or git commit if using --no-commit

# Create detailed tag
git tag -a v2.0.0 -m "Release v2.0.0: Complete Uninstall System

Major Features:
- Universal uninstall functions for all 7 dev-modules
- Universal test framework with 14 assertion types
- Common utility library with 9 helper functions
- Central uninstall orchestrator with interactive mode
- Comprehensive test coverage (110+ tests, 100% pass rate)
- DRY_RUN safety mode for risk-free previews
- FORCE mode for automation
- Complete documentation (UNINSTALL.md)

Modules Complete:
- Utilities (jq, ripgrep, fd-find, etc.)
- VS Code
- Node.js (nvm)
- Python (pyenv)
- Rust (rustup)
- Go
- Docker (with safety checks)

Quality Metrics:
- 110+ tests passing (100% pass rate)
- Zero shellcheck warnings
- Production-ready code quality
- Comprehensive safety checks
- Full backup system

Total Implementation: 2,600+ lines of code
Development Time: ~17 hours
Test Coverage: 100%"
```

**Minutes 115-120: Push and celebrate**
```bash
# Push main branch
git push origin main

# Push tag
git push origin v2.0.0

# Verify on GitHub
# Check releases page
# Verify tag created

# Clean up feature branch (optional)
git branch -d feature/module-uninstalls-batch2
git push origin --delete feature/module-uninstalls-batch2

# 🎉 DONE! 🎉
```

### Session 4 Acceptance Criteria

- ✅ UNINSTALL.md complete and accurate
- ✅ README.md updated
- ✅ RELEASE_NOTES.md updated
- ✅ All documentation links working
- ✅ All tests passing
- ✅ Merged to main
- ✅ v2.0.0 tagged
- ✅ All changes pushed

---

## Quick Reference

### Session Sequence

1. **Session 1:** Python + Rust (2-3h) - Easiest modules
2. **Session 2:** Go + Docker (4-5h) - Complex modules
3. **Session 3:** Orchestrator + Integration (3-4h) - Central system
4. **Session 4:** Documentation + Release (2h) - Finalization

**Total Time:** 11-14 hours  
**Sessions:** 4 sessions  
**Ideal Schedule:** 2 sessions per week = 2 weeks total

### Session Dependencies

```
Session 1 (Python + Rust)
    ↓
Session 2 (Go + Docker) ← Depends on Session 1 pattern
    ↓
Session 3 (Orchestrator) ← Depends on all modules complete
    ↓
Session 4 (Docs + Release) ← Depends on everything
```

### Time Optimization Tips

**To save time:**
- Copy test templates exactly (don't reinvent)
- Use common.sh helpers (already debugged)
- DRY_RUN mode for all development (prevents accidents)
- Commit early, commit often (clean history)

**Time multipliers:**
- Good music 🎵 (+10% speed)
- Fresh coffee ☕ (+15% speed)
- Uninterrupted blocks 🚫 (+20% speed)
- Clear mind 🧘 (+25% speed)

**Total potential speedup:** ~70% faster = 11h → 6.5h  
**Realistic speedup:** ~30% faster = 11h → 8h

### Emergency Procedures

**If stuck on a bug:**
1. Check shellcheck first
2. Run test in isolation
3. Add debug logging
4. Compare with working module
5. Take 5-minute break
6. Ask for help (GitHub Copilot, docs)

**If running out of time:**
- Prioritize: Python → Rust → Go → Docker
- Document what's incomplete
- Commit working parts
- Resume next session

**If tests failing:**
1. Read error message carefully
2. Check recent changes (git diff)
3. Run single test in isolation
4. Verify test framework working (run known-good test)
5. Bisect if needed (git bisect)

---

## Success Celebration Plan

### After Each Session

- ✅ Review what was accomplished
- ✅ Update progress metrics
- ✅ Commit with descriptive message
- ✅ Push to remote (backup)
- ✅ Small celebration (coffee, stretch, etc.)

### After Session 4 (Release)

- 🎉 Project complete!
- 📊 Calculate final metrics
- 📝 Write completion summary
- 🚀 Announce to team (if applicable)
- 🎯 Plan next phase

### Metrics to Celebrate

- ✅ 7/7 modules complete (100%)
- ✅ 110+ tests passing (100% pass rate)
- ✅ 0 shellcheck warnings
- ✅ 2,600+ lines of code
- ✅ Complete documentation
- ✅ Production-ready quality

---

**Document Version:** 1.0  
**Created:** November 4, 2025  
**Last Updated:** November 4, 2025  
**Next Update:** After each session completion
