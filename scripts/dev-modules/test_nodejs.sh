#!/usr/bin/env bash
# Test suite for Node.js (nvm) module

set -euo pipefail

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "${REPO_DIR}/scripts/lib/test_framework.sh"

# Source common utilities
source "${REPO_DIR}/scripts/lib/common.sh"

# Source Node.js module
source "${TEST_SCRIPT_DIR}/nodejs.sh"

###############################################################################
# Test Cases
###############################################################################

test_nodejs_syntax() {
    local syntax_check
    syntax_check=$(bash -n "${TEST_SCRIPT_DIR}/nodejs.sh" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "nodejs.sh has valid syntax"
        return 0
    else
        test_fail "nodejs.sh has syntax errors: $syntax_check"
        return 1
    fi
}

test_nodejs_functions_exist() {
    if declare -f install_nodejs >/dev/null 2>&1; then
        test_pass "install_nodejs function exists"
    else
        test_fail "install_nodejs function NOT defined"
    fi
    
    if declare -f uninstall_nodejs >/dev/null 2>&1; then
        test_pass "uninstall_nodejs function exists"
    else
        test_fail "uninstall_nodejs function NOT defined"
    fi
    
    if declare -f is_nodejs_installed >/dev/null 2>&1; then
        test_pass "is_nodejs_installed function exists"
    else
        test_fail "is_nodejs_installed function NOT defined"
    fi
    
    if declare -f backup_nodejs_config >/dev/null 2>&1; then
        test_pass "backup_nodejs_config function exists"
    else
        test_fail "backup_nodejs_config function NOT defined"
    fi
}

test_nodejs_detection() {
    if is_nodejs_installed; then
        test_pass "Node.js/nvm detection works (installed)"
        
        # Additional check for nvm directory
        if [[ -d "$HOME/.nvm" ]]; then
            test_pass "nvm directory exists: $HOME/.nvm"
        fi
    else
        test_skip "Node.js/nvm not installed" "install it to test detection"
    fi
}

test_nodejs_nvm_directory() {
    if [[ -d "$HOME/.nvm" ]]; then
        test_pass "nvm directory exists"
        
        # Check for nvm.sh
        if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
            test_pass "nvm.sh script exists"
        else
            test_fail "nvm.sh script NOT found in ~/.nvm"
        fi
    else
        test_skip "nvm directory not found" "not installed"
    fi
}

test_nodejs_shell_config() {
    # Check if shell configs contain nvm setup
    local has_nvm_config=0
    
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -q "NVM_DIR" "$HOME/.bashrc" 2>/dev/null; then
            test_pass "nvm config found in ~/.bashrc"
            has_nvm_config=1
        fi
    fi
    
    if [[ -f "$HOME/.profile" ]]; then
        if grep -q "NVM_DIR" "$HOME/.profile" 2>/dev/null; then
            test_pass "nvm config found in ~/.profile"
            has_nvm_config=1
        fi
    fi
    
    if [[ $has_nvm_config -eq 0 ]]; then
        test_skip "No nvm config in shell files" "not installed or different shell"
    fi
}

test_nodejs_command_availability() {
    if command -v node >/dev/null 2>&1; then
        local version
        version=$(node --version 2>/dev/null || echo "unknown")
        test_pass "node command available (version: $version)"
    else
        test_skip "node command not available" "not installed"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        local version
        version=$(npm --version 2>/dev/null || echo "unknown")
        test_pass "npm command available (version: $version)"
    else
        test_skip "npm command not available" "not installed"
    fi
}

test_nodejs_dry_run_uninstall() {
    local before_installed
    before_installed=$(is_nodejs_installed && echo "yes" || echo "no")
    
    # Run uninstall in dry-run mode
    DRY_RUN=1 FORCE=1 uninstall_nodejs >/dev/null 2>&1 || true
    
    local after_installed
    after_installed=$(is_nodejs_installed && echo "yes" || echo "no")
    
    if [[ "$after_installed" == "$before_installed" ]]; then
        test_pass "DRY_RUN mode did not change installation state"
    else
        test_fail "DRY_RUN mode changed installation state (before: $before_installed, after: $after_installed)"
    fi
}

test_nodejs_backup_function() {
    local temp_backup
    temp_backup=$(mktemp -d)
    
    if backup_nodejs_config "$temp_backup/test-backup" >/dev/null 2>&1; then
        if [[ -d "$temp_backup/test-backup" ]]; then
            test_pass "Backup function creates directory"
            
            # Check if shell configs were backed up (if they exist)
            if [[ -f "$HOME/.bashrc" ]] && [[ -f "$temp_backup/test-backup/.bashrc" ]]; then
                test_pass "Backup function backed up .bashrc"
            fi
            
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

test_nodejs_uninstall_with_force() {
    if ! is_nodejs_installed; then
        test_skip "Cannot test uninstall" "Node.js/nvm not installed"
        return 0
    fi
    
    # Test with dry-run + force (safe to test)
    if DRY_RUN=1 FORCE=1 uninstall_nodejs >/dev/null 2>&1; then
        test_pass "Uninstall accepts FORCE=1 flag"
    else
        test_fail "Uninstall failed with FORCE=1 flag"
    fi
}

test_nodejs_not_installed_handling() {
    # Test behavior when Node.js is not installed
    DRY_RUN=1 FORCE=1 uninstall_nodejs >/dev/null 2>&1
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        test_pass "Uninstall handles 'not installed' state gracefully (exit 0)"
    else
        test_fail "Uninstall failed when handling uninstalled state (exit $exit_code)"
    fi
}

test_nodejs_shell_cleanup_patterns() {
    # Test that we have proper patterns defined for shell cleanup
    # This is a code inspection test
    
    if grep -q 'export NVM_DIR' "${TEST_SCRIPT_DIR}/nodejs.sh"; then
        test_pass "Uninstall script includes NVM_DIR cleanup pattern"
    else
        test_fail "Uninstall script missing NVM_DIR cleanup pattern"
    fi
    
    if grep -q 'nvm.sh' "${TEST_SCRIPT_DIR}/nodejs.sh"; then
        test_pass "Uninstall script includes nvm.sh cleanup pattern"
    else
        test_fail "Uninstall script missing nvm.sh cleanup pattern"
    fi
}

###############################################################################
# Main Test Runner
###############################################################################

main() {
    test_suite_header "Node.js (nvm) Module Test Suite"
    
    run_test test_nodejs_syntax
    run_test test_nodejs_functions_exist
    run_test test_nodejs_detection
    run_test test_nodejs_nvm_directory
    run_test test_nodejs_shell_config
    run_test test_nodejs_command_availability
    run_test test_nodejs_dry_run_uninstall
    run_test test_nodejs_backup_function
    run_test test_nodejs_uninstall_with_force
    run_test test_nodejs_not_installed_handling
    run_test test_nodejs_shell_cleanup_patterns
    
    test_report
}

main "$@"
