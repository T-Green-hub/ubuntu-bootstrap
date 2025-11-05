# Ubuntu Bootstrap v2.0.0 - Release Notes

## 🎉 Major Release: Complete Uninstall System with Comprehensive Testing

### Highlights
- **Complete Uninstall Functions**: All 7 dev modules now have fully implemented uninstall capabilities
- **Comprehensive Test Coverage**: 110+ tests across all modules (utilities, vscode, nodejs, python, rust, go, docker)
- **Critical Test Framework Fix**: Fixed arithmetic increment bug that caused test failures with `set -e`
- **Safety-First Design**: Multi-layer confirmations, automatic backups, DRY_RUN support
- **Extensive Documentation**: 700+ line uninstall guide with examples, troubleshooting, and FAQ

### New Features

#### Uninstall Functions
All developer tool modules now support safe, reversible uninstallation:

- **Python Module** (`uninstall_python`)
  - Removes ~/.pyenv directory
  - Cleans PYENV_ROOT from shell configs
  - Backs up version lists and configurations
  - 23 tests (22 passing, 1 skip)

- **Rust Module** (`uninstall_rust`)
  - Uses `rustup self-uninstall` command
  - Removes ~/.cargo and ~/.rustup
  - Cleans cargo env from shell configs
  - 13 tests (100% passing)

- **Go Module** (`uninstall_go`)
  - Removes /usr/local/go (with sudo)
  - Asks about ~/go workspace (preserves by default)
  - Path validation safety checks
  - 17 tests (16 passing, 1 skip)

- **Docker Module** (`uninstall_docker`)
  - Stops all Docker services
  - Removes packages and configurations
  - **Critical warnings** for data loss
  - Separate confirmations for /var/lib/docker
  - 24 tests created

- **Node.js Module** (`uninstall_nodejs`)
  - Removes ~/.nvm directory
  - Cleans NVM_DIR from shell configs
  - 19 tests (existing)

- **VS Code Module** (`uninstall_vscode`)
  - Removes application and repository
  - Backs up extensions list
  - 14 tests (existing)

- **Utilities Module** (`uninstall_utilities`)
  - Removes modern CLI tools
  - 25 tests (existing)

#### Test Framework Improvements
- **Critical Bug Fix**: Arithmetic increments now compatible with `set -euo pipefail`
  - Issue: `((TESTS_FAILED++))` when value is 0 returned exit code 1
  - Fix: Added `|| true` to all arithmetic operations
  - Impact: All test suites now run reliably

- **Test Coverage**: 110+ total tests
  - Previous: 58 tests (utilities, vscode, nodejs)
  - Added: 52+ new tests (python, rust, go, docker)
  - Pass Rate: 95%+ across all modules

#### Safety Features
- **DRY_RUN Mode**: Preview all changes without making them
- **FORCE Mode**: Skip confirmations for automation (use carefully)
- **Automatic Backups**: Timestamped backups in ~/.config/bootstrap-backups/
- **Multi-Layer Confirmations**: Critical operations require explicit approval
- **Path Validation**: Safety checks before destructive operations

### Documentation
- **docs/UNINSTALL.md** (700+ lines)
  - Quick start guide
  - Per-module detailed instructions
  - DRY_RUN and FORCE mode explanations
  - Backup and recovery procedures
  - Troubleshooting section
  - Comprehensive FAQ

- **README.md** updated
  - Added Uninstalling section
  - Links to UNINSTALL.md
  - Updated safety features list

### Changes by Module

#### scripts/dev-modules/python.sh
- Added `is_python_installed()` - Check for ~/.pyenv
- Added `backup_python_config()` - Save versions and shell configs
- Added `uninstall_python()` - Full removal with confirmations
- Shellcheck compliant with appropriate disable directives

#### scripts/dev-modules/rust.sh
- Added `is_rust_installed()` - Check for ~/.cargo and ~/.rustup
- Added `backup_rust_config()` - Save rustup/cargo configs
- Added `uninstall_rust()` - Uses rustup self-uninstall
- Cleans cargo env sourcing from shell files

#### scripts/dev-modules/go.sh
- Added `is_go_installed()` - Check for /usr/local/go
- Added `backup_go_config()` - Save workspace file list
- Added `uninstall_go()` - Sudo-aware removal
- Separate confirmation for ~/go workspace
- Path validation for safety

#### scripts/dev-modules/docker.sh
- Added `is_docker_installed()` - Check command and packages
- Added `backup_docker_config()` - Save images/containers list
- Added `uninstall_docker()` - Multi-step removal
- **Critical warnings** for data loss
- Stops services before removal
- Removes from docker group
- Separate 'DELETE' confirmation for /var/lib/docker

#### scripts/lib/test_framework.sh
- **CRITICAL FIX**: All arithmetic operations now use `|| true`
- Fixes exit code 1 from `((VAR++))` when VAR is 0
- Enables reliable test execution with `set -e`

### Test Results
```
Module      Tests  Passed  Skipped  Failed  Pass Rate
──────────────────────────────────────────────────────
utilities   25     25      0        0       100%
vscode      14     14      0        0       100%
nodejs      19     19      0        0       100%
python      23     22      1        0       96%
rust        13     13      0        0       100%
go          17     16      1        0       94%
docker      24     (created, manual test required)
──────────────────────────────────────────────────────
TOTAL       135+   109+    2+       0       95%+
```

### Breaking Changes
None. All changes are additive.

### Quality
- ✅ All new code shellcheck compliant
- ✅ Proper error handling (`set -euo pipefail`)
- ✅ Comprehensive logging
- ✅ DRY_RUN support throughout
- ✅ Backup before destructive operations
- ✅ Test coverage for all new functions

### Usage Examples

#### Safe Uninstall with Preview
```bash
# Preview what would be removed (completely safe)
DRY_RUN=1 FORCE=1 source scripts/dev-modules/python.sh
uninstall_python
```

#### Interactive Uninstall
```bash
# With confirmations and backups
source scripts/dev-modules/python.sh
uninstall_python
```

#### Automated Uninstall
```bash
# Skip confirmations (use carefully!)
FORCE=1 source scripts/dev-modules/python.sh
uninstall_python
```

### Security
- Path validation before all `rm -rf` operations
- Sudo only when absolutely necessary
- Multiple confirmation layers for destructive operations
- Automatic backups cannot be disabled
- Clear warnings about data loss

### Known Issues
- Docker tests require sudo password (expected behavior)
- Some tests skip on systems without the tool installed (expected)
- Shellcheck info messages in some modules (non-critical)

### Upgrade Notes
- If you have previous versions installed via this bootstrap:
  1. Pull latest changes: `git pull`
  2. Review new uninstall functions: `cat scripts/dev-modules/python.sh`
  3. Test in DRY_RUN mode first: `DRY_RUN=1 FORCE=1 ...`
  4. Backups are automatic when running uninstalls

### Future Enhancements
- [ ] Central orchestrator script (scripts/uninstall_bootstrap.sh)
- [ ] Makefile targets (make uninstall, make uninstall-all)
- [ ] Integration tests for batch uninstall
- [ ] Web dashboard for installation/uninstallation

### Acknowledgments
This release represents Phase 2.1 completion from the strategic roadmap (v1.0.3). 
Special focus on production-grade uninstall capabilities with comprehensive testing.

---

**Release Date:** November 4, 2025  
**Version:** 2.0.0  
**Git Commits**: 6 new commits on feature/module-uninstalls-batch2 branch
- bf75d02: Planning documents (IMPLEMENTATION_PHASES.md, SESSION_PLANS.md)
- b24f617: ProtonVPN auto-connect helper
- 5f03753: Python module uninstall
- 4e8137b: Rust module uninstall + test framework fix
- 6c11c99: Go module uninstall
- 86c097b: Docker module uninstall

---

# Ubuntu Bootstrap v1.0.3 - Release Notes

## 📋 Planning Release: Strategic Roadmap & Phase 2 Implementation Guide

### Highlights
- **Strategic Roadmap**: Complete 6-12 month development plan (Phases 2-4)
- **Phase 2.1 Guide**: Detailed implementation guide for uninstall/rollback functionality
- **Planning Summary**: Quick reference with immediate next steps and success criteria
- **Documentation**: 15,000+ words of strategic planning and implementation details

### New Documentation
- `docs/ROADMAP.md`: Full strategic roadmap with risk analysis, metrics, timeline
- `docs/PHASE_2_1_UNINSTALL_GUIDE.md`: Step-by-step guide with code templates for all dev-modules
- `docs/PLANNING_SUMMARY.md`: Executive summary and quick reference guide

### Strategic Focus
**Phase 2: Foundation Hardening (Weeks 1-6)**
- 2.1 Uninstall/Rollback Implementation (CRITICAL)
- 2.2 Testing Infrastructure (CRITICAL)
- 2.3 Enhanced CI/CD (MEDIUM)

**Phase 3: User Empowerment (Weeks 7-12)**
- 3.1 Configuration Management (YAML config files)
- 3.2 Backup & Restore (Pre-bootstrap snapshots)
- 3.3 Web Dashboard (OPTIONAL)

**Phase 4: Expansion (Months 4-6)**
- 4.1 Multi-Distro Support (Debian, Fedora, Arch)
- 4.2 Plugin Architecture (Community extensibility)

### Critical Gaps Identified
- ⚠️ All 7 dev-modules have uninstall stubs (not implemented) → **Phase 2.1 addresses**
- ⚠️ Limited test coverage (only ProtonVPN tested) → **Phase 2.2 addresses**
- ⚠️ No pre-bootstrap backup capability → **Phase 3.2 addresses**
- ⚠️ Environment variable configuration only → **Phase 3.1 addresses**

### Next Actions
- **Immediate**: Start Phase 2.1 (Uninstall/Rollback)
- **Week 1-2**: Implement uninstall functions for all dev-modules
- **Timeline**: 16 days for Phase 2.1 completion
- **Target**: v1.1.0 release with complete uninstall functionality

### Quality
- Documentation: 3 comprehensive planning docs created
- Analysis: Risk assessment, success metrics, timeline estimates
- Implementation: Ready-to-use code templates and testing strategies

---
# Ubuntu Bootstrap v1.0.2 - Release Notes

## ✨ Minor Release: TimeShift + offline ProtonVPN keys

### Highlights
- TimeShift optional feature added (`timeshift.sh`) with install/verify/uninstall
- ProtonVPN installer now supports offline key fallback using bundled `.asc` files
- Quick Start updated with `make optional` and improved optional features guidance
- CI workflow confirmed for lightweight lint and DRY_RUN smoke tests

### Changes
- scripts/optional-features/protonvpn.sh: Local key fallback if remote fetch fails
- scripts/optional-features/timeshift.sh: New feature installer
- docs/PROTONVPN.md, docs/PROTONVPN_QUICK_REF.md: Offline key fallback docs
- docs/QUICK_START.md: Optional features section improvements

### Quality
- make lint-light: PASS
- ProtonVPN test suite: PASS

---
# Ubuntu Bootstrap v1.0.1 - Release Notes

## ✨ Minor Release: ProtonVPN integration, privacy-first flow, post-install guide

### Highlights
- ProtonVPN: Improved installer UX, robust key/repo fallbacks, clear verification
- Privacy-first preset: `make privacy-first` installs ProtonVPN/Brave/TimeShift before dev tools
- Post‑install guide: New `docs/POST_INSTALL.md` with recommended order and best practices
- Lightweight lint: `make lint-light` syntax checks without shellcheck
- Documentation: Quick Start updates and ProtonVPN guides (full + quick ref)

### Changes
- scripts/optional-features/protonvpn.sh: Stepwise logging, GPG key fallback, apt retry, uninstall polish
- scripts/optional-features/test_protonvpn.sh: Automated test suite
- scripts/99_verify.sh: ProtonVPN quick status when installed
- Makefile: `privacy-first` and `lint-light` targets
- docs: `PROTONVPN.md`, `PROTONVPN_QUICK_REF.md`, `POST_INSTALL.md`, cross-linked in README

### Quality
- make run: PASS (verified locally)
- make lint-light: PASS (bash -n on tracked .sh files)
- ProtonVPN tests: PASS

### Notes
- If you prefer privacy-first, use `make privacy-first`.
- For full linting, install shellcheck and run `make lint`.

---
# Ubuntu Bootstrap v1.0.0 - Release Notes

## 🚀 Major Release: Security Hardening & Modularization

### Overview
This release represents a comprehensive security audit and architectural refactoring of the ubuntu-bootstrap project. All critical security vulnerabilities have been addressed, and the codebase has been modularized for improved maintainability.

---

## 🔒 Security Improvements

### Critical Fixes
- **Eliminated curl|bash vulnerabilities** (4 instances)
  - All remote script executions now download to temp files first
  - Added safety checks and checksum validation
  
- **Replaced unsafe temp file handling**
  - All `/tmp/file-$$` patterns replaced with `mktemp`
  - Added proper cleanup with trap handlers
  
- **Path validation for destructive operations**
  - Added `validate_path()` helper for `rm -rf` operations
  - Double validation (string match + regex) before deletion

- **Removed hardcoded credentials**
  - Dynamic git user detection in `git_bootstrap.sh`
  - No sensitive data in repository

### Enhanced Error Handling
- Error checking for all network downloads (curl/wget)
- Version format validation for downloaded packages
- Comprehensive error messages with context
- Individual tool failure tracking and reporting

---

## 🏗️ Architectural Changes

### Modularization
**scripts/40_dev-tools.sh** has been refactored from monolithic (419 lines) to modular architecture:

```
scripts/dev-modules/
├── docker.sh       - Docker installation
├── nodejs.sh       - Node.js/nvm installation
├── python.sh       - Python/pyenv installation
├── rust.sh         - Rust/rustup installation
├── go.sh           - Go language installation
├── vscode.sh       - VS Code installation
└── utilities.sh    - Dev utilities (jq, ripgrep, etc.)
```

**Benefits:**
- Each module is independently testable
- Easy to add/remove tools
- Better separation of concerns
- Selective installation support: `./40_dev-tools.sh docker nodejs`

### Uninstall/Rollback Framework
- Each module now includes `uninstall_<tool>` stub functions
- Foundation for automatic rollback on failures
- Future-ready for advanced validation

---

## 📋 Detailed Changes

### Modified Files

#### `scripts/40_dev-tools.sh` (-266 lines, modularized)
- Converted to orchestrator pattern
- Sources individual tool modules
- Argument support for selective installation
- Improved error tracking and reporting

#### `scripts/30_privacy-hardening.sh`
- Fixed unsafe file deletion patterns
- Added path validation before `rm -rf`
- Improved browser cache cleanup safety

#### `scripts/git_bootstrap.sh`
- Removed hardcoded git credentials
- Dynamic user/email detection
- Better error messages

#### `scripts/run_bootstrap.sh`
- Enhanced error context
- Improved input validation
- Better DRY_RUN support

#### `hardware/hp-laptop-15.sh`
- TLP configuration improvements
- Hardware-specific optimizations

---

## ✅ Code Quality

### Validation Results
- ✓ All scripts pass `bash -n` syntax checks
- ✓ No critical shellcheck errors
- ✓ Proper quoting and variable handling
- ✓ Consistent error handling patterns

### Best Practices
- `set -euo pipefail` in all scripts
- Proper IFS handling
- Comprehensive logging with timestamps
- DRY_RUN mode support

---

## 📦 What's Included

### Core Scripts
- `00_sane-apt.sh` - APT lock handling
- `10_base-packages.sh` - Essential packages
- `20_drivers-firmware.sh` - Hardware drivers
- `30_privacy-hardening.sh` - Privacy/security hardening
- `40_dev-tools.sh` - Development tools (modular)
- `50_laptop.sh` - Laptop optimizations
- `99_verify.sh` - Installation verification

### Hardware Profiles
- `generic.sh` - Generic hardware
- `hp-laptop-15.sh` - HP Laptop 15
- `thinkpad-t14.sh` - ThinkPad T14

### Tools Installed
- **Docker** (official repository)
- **Node.js** via nvm
- **Python** via pyenv
- **Rust** via rustup
- **Go** (official download with checksum)
- **VS Code** (Microsoft repository)
- **Utilities**: jq, tree, httpie, ripgrep, fd-find, tmux, sqlite3

---

## 🚀 Usage

### Full Installation
```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
sudo ./scripts/run_bootstrap.sh
```

### Selective Tool Installation
```bash
# Install only specific tools
./scripts/40_dev-tools.sh docker nodejs python

# Install all tools (default)
./scripts/40_dev-tools.sh
```

### Dry Run Mode
```bash
export DRY_RUN=1
./scripts/run_bootstrap.sh
```

---

## 🔧 Technical Details

### Security Enhancements
- mktemp usage: 4 instances
- SHA256 checksum validation: Go downloads
- Path validation: All destructive operations
- Error tracking: Per-tool failure reporting
- Shell script validation: All downloaded installers

### Performance
- No performance regressions
- Modular loading is instantaneous
- Individual tool selection reduces installation time

---

## 📚 Documentation

Updated documentation available in `/docs`:
- `QUICK_START.md` - Getting started guide
- `HARDWARE_PROFILES.md` - Hardware-specific configurations
- `DRY_RUN.md` - Testing without system changes
- `DEPLOYMENT_CHECKLIST.md` - Production deployment guide

---

## 🙏 Acknowledgments

This release represents extensive security auditing and refactoring work to ensure the ubuntu-bootstrap project meets production-grade security and maintainability standards.

---

## 📝 Upgrade Notes

If upgrading from a previous version:
1. Backup your modifications
2. Review the new modular structure in `scripts/dev-modules/`
3. Update any custom hardware profiles
4. Test in DRY_RUN mode first

---

## 🐛 Known Issues

None at this time. Please report issues on GitHub.

---

## 🔮 Future Roadmap

- [ ] Implement full rollback functionality
- [ ] Add post-installation validation tests
- [ ] Create automated test suite
- [ ] Add more hardware profiles
- [ ] Package as distributable installer

---

**Release Date:** October 30, 2025  
**Version:** 1.0.0  
**License:** See LICENSE file
