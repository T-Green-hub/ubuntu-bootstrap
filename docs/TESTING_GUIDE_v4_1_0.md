# Testing Guide for v4.1.0

## Overview
This guide provides comprehensive testing procedures for ubuntu-bootstrap v4.1.0, covering syntax validation, dry-run tests, and real-world integration tests.

---

## 🧪 Test Levels

### Level 1: Syntax Validation (Always Safe)
No system changes, validates script syntax only.

```bash
# Test individual script
bash -n scripts/bootstrap.sh

# Test all scripts
make lint-light

# Full shellcheck (if installed)
make lint
```

**Expected Result**: Zero syntax errors.

---

### Level 2: Dry-Run Tests (Safe, No System Changes)
Simulates execution without making actual changes.

#### Quick Smoke Tests
```bash
make test-quick
```

**Tests**:
- Bootstrap minimal profile (30s timeout)
- Docker module dry-run
- Virtualization module dry-run

#### Comprehensive Dry-Run Suite
```bash
# All profiles
bash scripts/bootstrap.sh --profile minimal --dry-run --yes
bash scripts/bootstrap.sh --profile dev --dry-run --yes
bash scripts/bootstrap.sh --profile secure --dry-run --yes

# New modules
DRY_RUN=1 bash scripts/dev-modules/docker.sh
DRY_RUN=1 bash scripts/optional-features/virtualization.sh --virtualbox
DRY_RUN=1 bash scripts/optional-features/remote_tools.sh --openssh
```

**Expected Result**: Each script outputs "[DRY RUN]" or "Would" messages without prompting for sudo.

---

### Level 3: Module-Specific Tests
Test individual modules in isolation.

```bash
# Test all new v4.1.0 modules
make test-modules

# Or test individually
DRY_RUN=1 bash scripts/dev-modules/docker.sh --templates
DRY_RUN=1 bash scripts/optional-features/virtualization.sh --qemu
DRY_RUN=1 bash scripts/optional-features/remote_tools.sh --remmina
```

**Expected Result**: Each module completes without errors.

---

### Level 4: Health Check (Read-Only, Safe)
Verifies system state without modifications.

```bash
# Standard health check
bash scripts/checks/bootstrap_check.sh

# Doctor mode (extended checks)
bash scripts/checks/bootstrap_check.sh --doctor

# With custom output directory
bash scripts/checks/bootstrap_check.sh --output-dir /tmp/health-test
```

**Expected Result**: Health report generated, no sudo prompts for basic checks.

---

### Level 5: Full Test Suite (Requires ~2 minutes)
Comprehensive automated testing.

```bash
# Run complete v4.1.0 test suite
make test-v4

# Or run directly
bash scripts/tests/test_v4_1_0.sh
```

**Tests Included**:
- Syntax validation (all scripts)
- Library function checks
- Dry-run tests (minimal, dev, secure profiles)
- Module dry-runs (Docker, VM, Remote)
- Version verification
- Help output validation
- Health check execution
- File permissions audit

**Expected Result**: All tests PASS, summary shows 0 failures.

---

### Level 6: Real-World Integration Tests (Requires sudo)
⚠️ **WARNING**: These tests make actual system changes. Use on test systems only.

#### Preparation
```bash
# Create clean Ubuntu VM (recommended)
# - Ubuntu 24.04 LTS
# - 2 CPU cores, 4GB RAM, 20GB disk
# - Snapshot before testing

# Or use container
docker run -it --rm ubuntu:24.04 bash
```

#### Test 1: Minimal Profile (Production Simulation)
```bash
# Clone repo in test environment
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap

# Run minimal profile
sudo bash scripts/bootstrap.sh --profile minimal --yes

# Verify
bash scripts/checks/bootstrap_check.sh
```

**Expected Result**:
- APT packages updated
- Firmware checked
- UFW firewall enabled
- System snapshot created

#### Test 2: Dev Profile (Developer Workstation)
```bash
sudo bash scripts/bootstrap.sh --profile dev --yes

# Verify installations
node --version
python3 --version
docker --version  # Should be installed
git --version
```

**Expected Result**:
- All dev tools installed
- User added to docker group (requires logout/login)
- Build tools functional

#### Test 3: Secure Profile (Security Hardening)
```bash
sudo bash scripts/bootstrap.sh --profile secure --yes

# Verify security tools
sudo systemctl status ufw
sudo systemctl status fail2ban
sudo systemctl status clamav-freshclam
```

**Expected Result**:
- UFW active with default deny
- Fail2Ban monitoring SSH
- ClamAV optional (if user accepted)

#### Test 4: Docker with Templates
```bash
sudo bash scripts/dev-modules/docker.sh --templates

# Verify
ls ~/docker-templates/
docker --version
docker compose version

# Test template
cd /tmp
mkdir test-nginx && cd test-nginx
cp ~/docker-templates/nginx-compose.yml docker-compose.yml
docker compose up -d
curl http://localhost:8080
docker compose down
```

**Expected Result**:
- Templates created in ~/docker-templates/
- Nginx container runs successfully

#### Test 5: VirtualBox Setup
```bash
sudo bash scripts/optional-features/virtualization.sh --virtualbox

# Verify
virtualbox --help
groups | grep vboxusers
```

**Expected Result**:
- VirtualBox installed
- User added to vboxusers group

#### Test 6: Remote Tools
```bash
sudo bash scripts/optional-features/remote_tools.sh --openssh --remmina

# Verify SSH
sudo systemctl status ssh
ss -tlnp | grep :22

# Verify Remmina
remmina --version
```

**Expected Result**:
- SSH server running
- UFW allows OpenSSH
- Remmina GUI available

---

## 🔍 Debugging Failed Tests

### Common Issues

#### Issue 1: "Permission denied" in Dry-Run Mode
**Symptom**: Dry-run prompts for sudo password.

**Fix**: Check `run_privileged()` calls in scripts:
```bash
# Search for direct sudo calls
grep -r "sudo " scripts/ | grep -v "run_privileged"
```

**Expected**: All `sudo` commands should be wrapped with:
- `run_privileged <command>`
- Or guarded by `if (( DRY_RUN == 0 )); then sudo ...; fi`

#### Issue 2: Test Hangs
**Symptom**: Test times out after 30-60 seconds.

**Fix**: Check for interactive prompts:
```bash
# Run with explicit yes flag
bash scripts/bootstrap.sh --profile minimal --dry-run --yes

# Or set AUTO_YES
AUTO_YES=1 bash scripts/bootstrap.sh --profile minimal --dry-run
```

#### Issue 3: Module Test Fails
**Symptom**: Individual module test returns non-zero exit code.

**Debug**:
```bash
# Run with verbose output
set -x
DRY_RUN=1 bash scripts/dev-modules/docker.sh
set +x

# Check logs
tail -100 /tmp/bootstrap-*/bootstrap.log
```

#### Issue 4: Health Check Requires Sudo
**Symptom**: Health checker prompts for password.

**Expected Behavior**: Basic health checks should work without sudo. Some checks (like firmware status) may show "requires sudo" but shouldn't prompt.

**Fix**: Check for direct `sudo` usage in `bootstrap_check.sh`:
```bash
grep -n "sudo " scripts/checks/bootstrap_check.sh
```

---

## 📊 Test Coverage Matrix

| Component | Syntax | Dry-Run | Real Test | Automated |
|-----------|--------|---------|-----------|-----------|
| bootstrap.sh (minimal) | ✅ | ✅ | ⚠️ | ✅ |
| bootstrap.sh (dev) | ✅ | ✅ | ⚠️ | ✅ |
| bootstrap.sh (secure) | ✅ | ✅ | ⚠️ | ✅ |
| docker.sh | ✅ | ✅ | ⚠️ | ✅ |
| virtualization.sh | ✅ | ✅ | ⚠️ | ✅ |
| remote_tools.sh | ✅ | ✅ | ⚠️ | ✅ |
| feedback.sh | ✅ | ✅ | ⚠️ | ❌ |
| protonvpn.sh | ✅ | ✅ | ⚠️ | ❌ |
| dns_privacy.sh | ✅ | ✅ | ⚠️ | ❌ |
| customization.sh | ✅ | ✅ | ⚠️ | ❌ |
| profiles.sh | ✅ | ✅ | ⚠️ | ❌ |
| bootstrap_check.sh | ✅ | N/A | ✅ | ✅ |

Legend:
- ✅ Implemented
- ⚠️ Manual testing required
- ❌ Not yet automated

---

## 🚀 Quick Test Commands

### Before Committing Code
```bash
# 1. Syntax check
make lint-light

# 2. Dry-run test
make test-quick

# 3. Full automated suite
make test-v4
```

### Before Release
```bash
# 1. All automated tests
make test-all

# 2. Health check
bash scripts/checks/bootstrap_check.sh --doctor

# 3. Version verification
bash scripts/bootstrap.sh --version
```

### In CI/CD Pipeline
```bash
# Syntax validation
bash -n scripts/**/*.sh

# Dry-run tests (no sudo)
timeout 120 bash scripts/bootstrap.sh --profile minimal --dry-run --yes

# Health check (read-only)
bash scripts/checks/bootstrap_check.sh --output-dir /tmp/ci-health
```

---

## 📝 Test Checklist for v4.1.0 Release

### Pre-Release Testing
- [ ] All scripts pass `bash -n` syntax check
- [ ] Bootstrap profiles (minimal, dev, secure) complete in dry-run mode
- [ ] New modules (docker, virtualization, remote_tools) dry-run successfully
- [ ] Health checker runs without sudo for basic checks
- [ ] Version output shows 4.1.0
- [ ] Help output displays correctly
- [ ] Test suite completes with 0 failures

### Integration Testing (Test VM Required)
- [ ] Minimal profile installs on clean Ubuntu 24.04
- [ ] Dev profile installs with Docker
- [ ] Secure profile enables UFW + Fail2Ban
- [ ] Docker templates generate and work
- [ ] VirtualBox installs and VM creation works
- [ ] OpenSSH server starts and accepts connections
- [ ] Remmina launches successfully

### Documentation Testing
- [ ] README.md examples execute correctly
- [ ] QUICK_START_v4_1_0.md commands work
- [ ] MASTER_PROMPT_USAGE_GUIDE.md workflows functional
- [ ] Makefile targets execute as documented

---

## 🎯 Success Criteria

### Dry-Run Tests
- ✅ All profiles complete in <60 seconds
- ✅ No sudo prompts appear
- ✅ Output clearly shows "DRY RUN" or "Would" messages

### Real Tests
- ✅ System boots after bootstrap
- ✅ No broken packages (`dpkg -l | grep ^iU`)
- ✅ Health check shows green status
- ✅ All installed tools are functional

### Regression Tests
- ✅ Existing features still work (VPN, shell customization)
- ✅ No performance degradation (<2x previous runtime)
- ✅ Logs are readable and informative

---

**Version**: 4.1.0
**Last Updated**: January 13, 2026
**Test Environment**: Ubuntu 24.04 LTS (Noble Numbat)
