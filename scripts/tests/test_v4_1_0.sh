#!/usr/bin/env bash
# Comprehensive Test Suite for v4.1.0
# Tests all features from the Agent Mode Master Prompt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging
log_test() { echo -e "${BLUE}[TEST]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; ((TESTS_FAILED++)); }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Test helper
run_test() {
    local test_name="$1"
    shift
    ((TESTS_RUN++))
    log_test "$test_name"

    if "$@" &>/dev/null; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

echo "═══════════════════════════════════════════════════════════"
echo "  Ubuntu Bootstrap v4.1.0 - Comprehensive Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test 1: Syntax Validation
echo "Phase 1: Syntax Validation"
echo "───────────────────────────────────────────────────────────"
run_test "Bootstrap script syntax" bash -n "$REPO_DIR/scripts/bootstrap.sh"
run_test "Health checker syntax" bash -n "$REPO_DIR/scripts/checks/bootstrap_check.sh"
run_test "Docker module syntax" bash -n "$REPO_DIR/scripts/dev-modules/docker.sh"
run_test "Profiles module syntax" bash -n "$REPO_DIR/scripts/dev-modules/profiles.sh"
run_test "Virtualization module syntax" bash -n "$REPO_DIR/scripts/optional-features/virtualization.sh"
run_test "Remote tools module syntax" bash -n "$REPO_DIR/scripts/optional-features/remote_tools.sh"
run_test "Feedback module syntax" bash -n "$REPO_DIR/scripts/optional-features/feedback.sh"
run_test "ProtonVPN module syntax" bash -n "$REPO_DIR/scripts/optional-features/protonvpn.sh"
echo ""

# Test 2: Library Functions
echo "Phase 2: Library Functions"
echo "───────────────────────────────────────────────────────────"
run_test "Logging library syntax" bash -n "$REPO_DIR/scripts/lib/logging.sh"
run_test "Privileged library syntax" bash -n "$REPO_DIR/scripts/lib/privileged.sh"
run_test "Package library syntax" bash -n "$REPO_DIR/scripts/lib/package.sh"
run_test "Detection library syntax" bash -n "$REPO_DIR/scripts/lib/detection.sh"
run_test "Report library syntax" bash -n "$REPO_DIR/scripts/lib/report.sh"
run_test "Version library syntax" bash -n "$REPO_DIR/scripts/lib/version.sh"
echo ""

# Test 3: Dry-Run Tests (No System Changes)
echo "Phase 3: Dry-Run Tests (No System Changes)"
echo "───────────────────────────────────────────────────────────"

log_test "Bootstrap minimal profile (dry-run)"
if timeout 30 bash "$REPO_DIR/scripts/bootstrap.sh" --profile minimal --dry-run --yes 2>&1 | grep -q "DRY.RUN\|Would"; then
    log_pass "Bootstrap minimal profile (dry-run)"
else
    log_fail "Bootstrap minimal profile (dry-run)"
fi

log_test "Bootstrap dev profile (dry-run)"
if timeout 30 bash "$REPO_DIR/scripts/bootstrap.sh" --profile dev --dry-run --yes 2>&1 | grep -q "DRY.RUN\|Would"; then
    log_pass "Bootstrap dev profile (dry-run)"
else
    log_fail "Bootstrap dev profile (dry-run)"
fi

log_test "Bootstrap secure profile (dry-run)"
if timeout 30 bash "$REPO_DIR/scripts/bootstrap.sh" --profile secure --dry-run --yes 2>&1 | grep -q "DRY.RUN\|Would"; then
    log_pass "Bootstrap secure profile (dry-run)"
else
    log_fail "Bootstrap secure profile (dry-run)"
fi

log_test "Docker module (dry-run)"
if DRY_RUN=1 bash "$REPO_DIR/scripts/dev-modules/docker.sh" 2>&1 | grep -q "DRY RUN"; then
    log_pass "Docker module (dry-run)"
else
    log_fail "Docker module (dry-run)"
fi

log_test "Virtualization module (dry-run)"
if DRY_RUN=1 bash "$REPO_DIR/scripts/optional-features/virtualization.sh" --virtualbox 2>&1 | grep -q "DRY RUN"; then
    log_pass "Virtualization module (dry-run)"
else
    log_fail "Virtualization module (dry-run)"
fi

log_test "Remote tools module (dry-run)"
if DRY_RUN=1 bash "$REPO_DIR/scripts/optional-features/remote_tools.sh" --openssh 2>&1 | grep -q "DRY RUN"; then
    log_pass "Remote tools module (dry-run)"
else
    log_fail "Remote tools module (dry-run)"
fi

echo ""

# Test 4: Version Check
echo "Phase 4: Version Verification"
echo "───────────────────────────────────────────────────────────"
log_test "Version string check"
VERSION_OUTPUT=$(bash "$REPO_DIR/scripts/bootstrap.sh" --version 2>&1)
if echo "$VERSION_OUTPUT" | grep -q "4.1.0"; then
    log_pass "Version string check (4.1.0)"
else
    log_fail "Version string check (expected 4.1.0, got: $VERSION_OUTPUT)"
fi
echo ""

# Test 5: Help Output
echo "Phase 5: Help Output Verification"
echo "───────────────────────────────────────────────────────────"
run_test "Bootstrap help output" bash "$REPO_DIR/scripts/bootstrap.sh" --help
run_test "Health checker help output" bash "$REPO_DIR/scripts/checks/bootstrap_check.sh" --help
echo ""

# Test 6: Health Check (Read-Only)
echo "Phase 6: Health Check (Read-Only Operations)"
echo "───────────────────────────────────────────────────────────"
log_test "System health check"
if timeout 60 bash "$REPO_DIR/scripts/checks/bootstrap_check.sh" --output-dir /tmp/test-health 2>&1 | grep -q "Health"; then
    log_pass "System health check"
else
    log_fail "System health check"
fi
echo ""

# Test 7: File Permissions
echo "Phase 7: File Permissions"
echo "───────────────────────────────────────────────────────────"
for script in scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/dev-modules/*.sh scripts/optional-features/*.sh; do
    if [[ -x "$REPO_DIR/$script" ]]; then
        log_pass "Executable: $script"
    else
        log_warn "Not executable: $script"
    fi
done
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "  Test Summary"
echo "═══════════════════════════════════════════════════════════"
echo "  Total Tests:  $TESTS_RUN"
echo "  Passed:       $TESTS_PASSED"
echo "  Failed:       $TESTS_FAILED"
echo ""

if (( TESTS_FAILED == 0 )); then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    exit 1
fi
