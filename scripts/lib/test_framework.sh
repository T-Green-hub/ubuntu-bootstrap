#!/usr/bin/env bash
# Universal test framework for ubuntu-bootstrap
# Provides assertion helpers and test orchestration

set -euo pipefail

# ANSI colors
readonly T_GREEN='\033[0;32m'
readonly T_RED='\033[0;31m'
readonly T_YELLOW='\033[1;33m'
readonly T_BLUE='\033[0;34m'
readonly T_BOLD='\033[1m'
readonly T_NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test result tracking
declare -a FAILED_TESTS=()
declare -a SKIPPED_TESTS=()

###############################################################################
# Assertion Functions
###############################################################################

assert_command_exists() {
    local cmd="$1"
    local msg="${2:-Command '$cmd' should exist}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (NOT FOUND)"
        return 1
    fi
}

assert_command_not_exists() {
    local cmd="$1"
    local msg="${2:-Command '$cmd' should NOT exist}"
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (FOUND: $(command -v "$cmd" 2>/dev/null || echo 'unknown'))"
        return 1
    fi
}

assert_package_installed() {
    local pkg="$1"
    local msg="${2:-Package '$pkg' should be installed}"
    
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (NOT INSTALLED)"
        return 1
    fi
}

assert_package_not_installed() {
    local pkg="$1"
    local msg="${2:-Package '$pkg' should NOT be installed}"
    
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        test_pass "$msg"
        return 0
    else
        local version
        version=$(dpkg -s "$pkg" 2>/dev/null | grep -E '^Version:' | cut -d' ' -f2 || echo 'unknown')
        test_fail "$msg (INSTALLED: version $version)"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File '$file' should exist}"
    
    if [[ -f "$file" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (NOT FOUND)"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File '$file' should NOT exist}"
    
    if [[ ! -f "$file" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (EXISTS)"
        return 1
    fi
}

assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File '$file' should contain pattern}"
    
    if [[ ! -f "$file" ]]; then
        test_fail "$msg (FILE NOT FOUND)"
        return 1
    fi
    
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (PATTERN NOT FOUND)"
        return 1
    fi
}

assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-File '$file' should NOT contain pattern}"
    
    if [[ ! -f "$file" ]]; then
        test_pass "$msg (file doesn't exist)"
        return 0
    fi
    
    if ! grep -qF "$pattern" "$file" 2>/dev/null; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (PATTERN FOUND)"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory '$dir' should exist}"
    
    if [[ -d "$dir" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (NOT FOUND)"
        return 1
    fi
}

assert_dir_not_exists() {
    local dir="$1"
    local msg="${2:-Directory '$dir' should NOT exist}"
    
    if [[ ! -d "$dir" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (EXISTS)"
        return 1
    fi
}

assert_service_active() {
    local service="$1"
    local msg="${2:-Service '$service' should be active}"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (INACTIVE)"
        return 1
    fi
}

assert_service_enabled() {
    local service="$1"
    local msg="${2:-Service '$service' should be enabled}"
    
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (DISABLED)"
        return 1
    fi
}

assert_equal() {
    local actual="$1"
    local expected="$2"
    local msg="${3:-Expected '$expected', got '$actual'}"
    
    if [[ "$actual" == "$expected" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-String should contain '$needle'}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (NOT FOUND in: ${haystack:0:100}...)"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-String should NOT contain '$needle'}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg (FOUND in: ${haystack:0:100}...)"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-Expected exit code $expected, got $actual}"
    
    if [[ "$actual" -eq "$expected" ]]; then
        test_pass "$msg"
        return 0
    else
        test_fail "$msg"
        return 1
    fi
}

###############################################################################
# Test Running and Reporting
###############################################################################

test_pass() {
    local msg="$1"
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo -e "  ${T_GREEN}✓${T_NC} $msg"
}

test_fail() {
    local msg="$1"
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$msg")
    echo -e "  ${T_RED}✗${T_NC} $msg"
}

test_skip() {
    local msg="$1"
    local reason="${2:-}"
    ((TESTS_RUN++))
    ((TESTS_SKIPPED++))
    SKIPPED_TESTS+=("$msg")
    if [[ -n "$reason" ]]; then
        echo -e "  ${T_YELLOW}⊘${T_NC} $msg (SKIPPED: $reason)"
    else
        echo -e "  ${T_YELLOW}⊘${T_NC} $msg (SKIPPED)"
    fi
}

test_group() {
    local name="$1"
    echo ""
    echo -e "${T_BLUE}${T_BOLD}▶${T_NC} ${T_BOLD}$name${T_NC}"
}

run_test() {
    local test_name="$1"
    test_group "$test_name"
    "$test_name" || true
}

test_suite_header() {
    local suite_name="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${T_BOLD}  $suite_name${T_NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

test_report() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${T_BOLD}                  TEST SUMMARY${T_NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Total:   $TESTS_RUN"
    echo -e "  ${T_GREEN}Passed:  $TESTS_PASSED${T_NC}"
    
    if ((TESTS_FAILED > 0)); then
        echo -e "  ${T_RED}Failed:  $TESTS_FAILED${T_NC}"
    fi
    
    if ((TESTS_SKIPPED > 0)); then
        echo -e "  ${T_YELLOW}Skipped: $TESTS_SKIPPED${T_NC}"
    fi
    
    if ((TESTS_FAILED > 0)); then
        echo ""
        echo -e "${T_RED}${T_BOLD}Failed tests:${T_NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${T_RED}✗${T_NC} $test"
        done
    fi
    
    if ((TESTS_SKIPPED > 0)); then
        echo ""
        echo -e "${T_YELLOW}Skipped tests:${T_NC}"
        for test in "${SKIPPED_TESTS[@]}"; do
            echo -e "  ${T_YELLOW}⊘${T_NC} $test"
        done
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ((TESTS_FAILED > 0)); then
        exit 1
    else
        exit 0
    fi
}

###############################################################################
# Utility Functions
###############################################################################

# Check if running in dry-run mode
is_dry_run() {
    [[ "${DRY_RUN:-0}" -eq 1 ]]
}

# Check if running as root/sudo
is_root() {
    [[ "$EUID" -eq 0 ]]
}

# Get timestamp for backups
get_timestamp() {
    date +%Y%m%d-%H%M%S
}
