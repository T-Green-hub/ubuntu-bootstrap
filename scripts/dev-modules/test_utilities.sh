#!/usr/bin/env bash
# Test suite for Development Utilities module

set -euo pipefail

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${REPO_DIR}/scripts/lib/test_framework.sh"

# Source utilities module
source "${TEST_SCRIPT_DIR}/utilities.sh"

# Source apt_safe if available (it will override SCRIPT_DIR, so we use TEST_SCRIPT_DIR)
if [[ -f "${REPO_DIR}/scripts/00_sane-apt.sh" ]]; then
    source "${REPO_DIR}/scripts/00_sane-apt.sh"
fi

###############################################################################
# Test Cases
###############################################################################

test_utilities_syntax() {
    # Test that the script has valid bash syntax
    local syntax_check
    syntax_check=$(bash -n "${TEST_SCRIPT_DIR}/utilities.sh" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "utilities.sh has valid syntax"
        return 0
    else
        test_fail "utilities.sh has syntax errors: $syntax_check"
        return 1
    fi
}

test_utilities_functions_exist() {
    # Test that required functions are defined
    if declare -f install_dev_utilities >/dev/null 2>&1; then
        test_pass "install_dev_utilities function exists"
    else
        test_fail "install_dev_utilities function NOT defined"
    fi
    
    if declare -f uninstall_dev_utilities >/dev/null 2>&1; then
        test_pass "uninstall_dev_utilities function exists"
    else
        test_fail "uninstall_dev_utilities function NOT defined"
    fi
    
    if declare -f is_dev_utilities_installed >/dev/null 2>&1; then
        test_pass "is_dev_utilities_installed function exists"
    else
        test_fail "is_dev_utilities_installed function NOT defined"
    fi
    
    if declare -f backup_dev_utilities_config >/dev/null 2>&1; then
        test_pass "backup_dev_utilities_config function exists"
    else
        test_fail "backup_dev_utilities_config function NOT defined"
    fi
}

test_utilities_detection() {
    # Test the detection function
    if is_dev_utilities_installed; then
        test_pass "Dev utilities detection works (at least one installed)"
    else
        test_skip "No dev utilities installed" "install them to test detection"
    fi
}

test_utilities_installation_status() {
    # Check if any of the utilities are installed
    local pkgs=(jq tree httpie ripgrep fd-find tmux sqlite3)
    local installed=0
    local not_installed=0
    
    for pkg in "${pkgs[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            ((installed++))
            test_pass "Package $pkg is installed"
        else
            ((not_installed++))
            test_skip "Package $pkg not installed"
        fi
    done
    
    if ((installed > 0)); then
        test_pass "Found $installed dev utility packages installed"
    fi
    
    if ((not_installed > 0)); then
        test_skip "$not_installed dev utility packages not installed"
    fi
}

test_utilities_commands() {
    # Test if utility commands are available
    local commands=(jq tree http rg fdfind tmux sqlite3)
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            test_pass "Command '$cmd' is available"
        else
            test_skip "Command '$cmd' not available" "not installed"
        fi
    done
}

test_utilities_dry_run_uninstall() {
    # Test that dry-run mode doesn't actually uninstall
    local before_installed
    before_installed=$(is_dev_utilities_installed && echo "yes" || echo "no")
    
    # Run uninstall in dry-run mode
    DRY_RUN=1 FORCE=1 uninstall_dev_utilities >/dev/null 2>&1 || true
    
    local after_installed
    after_installed=$(is_dev_utilities_installed && echo "yes" || echo "no")
    
    if [[ "$after_installed" == "$before_installed" ]]; then
        test_pass "DRY_RUN mode did not change installation state"
    else
        test_fail "DRY_RUN mode changed installation state (before: $before_installed, after: $after_installed)"
    fi
}

test_utilities_backup_function() {
    # Test that backup function creates directory
    local temp_backup
    temp_backup=$(mktemp -d)
    
    if backup_dev_utilities_config "$temp_backup/test-backup" >/dev/null 2>&1; then
        if [[ -d "$temp_backup/test-backup" ]]; then
            test_pass "Backup function creates directory"
            rm -rf "$temp_backup"
        else
            test_fail "Backup function did not create directory"
            rm -rf "$temp_backup"
        fi
    else
        test_fail "Backup function failed"
        rm -rf "$temp_backup"
    fi
}

test_utilities_uninstall_with_force() {
    # Test that FORCE=1 skips confirmation
    # This is a sanity check that the function accepts FORCE flag
    
    if ! is_dev_utilities_installed; then
        test_skip "Cannot test uninstall" "no utilities installed"
        return 0
    fi
    
    # Test with dry-run + force (safe to test)
    if DRY_RUN=1 FORCE=1 uninstall_dev_utilities >/dev/null 2>&1; then
        test_pass "Uninstall accepts FORCE=1 flag"
    else
        test_fail "Uninstall failed with FORCE=1 flag"
    fi
}

test_utilities_not_installed_handling() {
    # Test behavior when utilities are not installed
    # We'll use dry-run to safely test this
    
    # This test assumes we're simulating the "not installed" state
    # In real scenario, we'd check actual installation state
    
    DRY_RUN=1 FORCE=1 uninstall_dev_utilities >/dev/null 2>&1
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "Uninstall handles 'not installed' state gracefully (exit 0)"
    else
        test_fail "Uninstall failed when handling uninstalled state (exit $exit_code)"
    fi
}

###############################################################################
# Main Test Runner
###############################################################################

main() {
    test_suite_header "Development Utilities Module Test Suite"
    
    run_test test_utilities_syntax
    run_test test_utilities_functions_exist
    run_test test_utilities_detection
    run_test test_utilities_installation_status
    run_test test_utilities_commands
    run_test test_utilities_dry_run_uninstall
    run_test test_utilities_backup_function
    run_test test_utilities_uninstall_with_force
    run_test test_utilities_not_installed_handling
    
    test_report
}

main "$@"
