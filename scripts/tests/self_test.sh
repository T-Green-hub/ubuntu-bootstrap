#!/usr/bin/env bash
# Ubuntu Bootstrap - Self-Test Harness
# Validates scripts, runs smoke tests, verifies artifacts

set -euo pipefail
IFS=$'\n\t'

# Determine directories
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

# Test result
test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((TESTS_WARNED++))
}

# Test: Syntax check
test_syntax_check() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Bash Syntax Check"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local failed=0
    for script in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh "$SCRIPT_DIR"/checks/*.sh "$SCRIPT_DIR"/tests/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                test_pass "$(basename "$script")"
            else
                test_fail "$(basename "$script") - syntax error"
                failed=1
            fi
        fi
    done

    if (( failed == 0 )); then
        echo ""
        echo "All scripts passed syntax check"
    fi
}

# Test: Help and version flags
test_help_version() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Help and Version Flags"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Bootstrap help
    if bash "$SCRIPT_DIR/bootstrap.sh" --help >/dev/null 2>&1; then
        test_pass "bootstrap.sh --help"
    else
        test_fail "bootstrap.sh --help"
    fi

    # Bootstrap version
    if bash "$SCRIPT_DIR/bootstrap.sh" --version >/dev/null 2>&1; then
        test_pass "bootstrap.sh --version"
    else
        test_fail "bootstrap.sh --version"
    fi

    # Checker help
    if bash "$SCRIPT_DIR/checks/bootstrap_check.sh" --help >/dev/null 2>&1; then
        test_pass "bootstrap_check.sh --help"
    else
        test_fail "bootstrap_check.sh --help"
    fi

    # Checker version
    if bash "$SCRIPT_DIR/checks/bootstrap_check.sh" --version >/dev/null 2>&1; then
        test_pass "bootstrap_check.sh --version"
    else
        test_fail "bootstrap_check.sh --version"
    fi
}

# Test: Dry-run profiles
test_dry_run_profiles() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Dry-Run Profiles"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local profiles=("minimal" "dev" "secure")
    for profile in "${profiles[@]}"; do
        local output_dir="/tmp/bs_${profile}_v404_$$"
        echo "Testing profile: $profile (output: $output_dir)"

        if bash "$SCRIPT_DIR/bootstrap.sh" --profile "$profile" --dry-run --yes --output-dir "$output_dir" >/dev/null 2>&1; then
            # Verify artifacts exist
            if [[ -f "$output_dir/report.json" ]] && [[ -f "$output_dir/report.txt" ]] && [[ -f "$output_dir/system-info.txt" ]]; then
                test_pass "Profile $profile: artifacts created"
            else
                test_fail "Profile $profile: missing artifacts"
            fi

            # Cleanup
            rm -rf "$output_dir"
        else
            test_fail "Profile $profile: execution failed"
        fi
    done
}

# Test: Health checker
test_health_checker() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Health Checker"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local output_dir="/tmp/ck_test_v404_$$"
    echo "Running health checker (output: $output_dir)"

    if bash "$SCRIPT_DIR/checks/bootstrap_check.sh" --output-dir "$output_dir" >/dev/null 2>&1; then
        # Verify artifacts exist
        local json_file=$(ls "$output_dir"/health-check-*.json 2>/dev/null | head -1)
        local text_file=$(ls "$output_dir"/health-check-*.txt 2>/dev/null | head -1)

        if [[ -f "$json_file" ]] && [[ -f "$text_file" ]]; then
            test_pass "Health checker: artifacts created"

            # Validate JSON
            if command -v python3 >/dev/null 2>&1; then
                if python3 -m json.tool "$json_file" >/dev/null 2>&1; then
                    test_pass "Health checker: JSON valid"
                else
                    test_fail "Health checker: JSON invalid"
                fi
            else
                test_warn "Health checker: JSON validation skipped (python3 not available)"
            fi
        else
            test_fail "Health checker: missing artifacts"
        fi

        # Cleanup
        rm -rf "$output_dir"
    else
        test_fail "Health checker: execution failed"
    fi
}

# Test: Print-plan mode
test_print_plan() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Print-Plan Mode"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    if bash "$SCRIPT_DIR/bootstrap.sh" --profile minimal --print-plan >/dev/null 2>&1; then
        test_pass "Print-plan mode executed"
    else
        test_fail "Print-plan mode failed"
    fi
}

# Test: Doctor mode
test_doctor_mode() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Doctor Mode"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local output_dir="/tmp/doctor_test_v404_$$"

    # Bootstrap doctor
    if bash "$SCRIPT_DIR/bootstrap.sh" --doctor --output-dir "$output_dir" >/dev/null 2>&1; then
        test_pass "Bootstrap doctor mode executed"
        rm -rf "$output_dir"
    else
        test_fail "Bootstrap doctor mode failed"
    fi

    # Checker doctor
    output_dir="/tmp/checker_doctor_v404_$$"
    if bash "$SCRIPT_DIR/checks/bootstrap_check.sh" --doctor --output-dir "$output_dir" >/dev/null 2>&1; then
        test_pass "Checker doctor mode executed"
        rm -rf "$output_dir"
    else
        test_fail "Checker doctor mode failed"
    fi
}

# Test: Debug and trace modes
test_debug_trace() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Debug and Trace Modes"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Debug mode
    local output_dir="/tmp/debug_test_v404_$$"
    if bash "$SCRIPT_DIR/bootstrap.sh" --profile minimal --dry-run --yes --debug --output-dir "$output_dir" >/dev/null 2>&1; then
        test_pass "Debug mode executed"
        rm -rf "$output_dir"
    else
        test_fail "Debug mode failed"
    fi

    # Trace mode
    output_dir="/tmp/trace_test_v404_$$"
    if bash "$SCRIPT_DIR/bootstrap.sh" --profile minimal --dry-run --yes --trace --output-dir "$output_dir" >/dev/null 2>&1; then
        if [[ -f "$output_dir/trace.log" ]]; then
            test_pass "Trace mode: trace.log created"
        else
            test_fail "Trace mode: trace.log missing"
        fi
        rm -rf "$output_dir"
    else
        test_fail "Trace mode failed"
    fi
}

# Test: Bundle creation
test_bundle() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Test: Bundle Creation"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    local output_dir="/tmp/bundle_test_v404_$$"
    if bash "$SCRIPT_DIR/checks/bootstrap_check.sh" --bundle --output-dir "$output_dir" >/dev/null 2>&1; then
        if [[ -f "${output_dir}.tar.gz" ]]; then
            test_pass "Bundle: tar.gz created"
            rm -f "${output_dir}.tar.gz"
        else
            test_fail "Bundle: tar.gz missing"
        fi
        rm -rf "$output_dir"
    else
        test_fail "Bundle creation failed"
    fi
}

# Summary
print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Self-Test Summary"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "  ✓ Passed: $TESTS_PASSED"
    echo "  ✗ Failed: $TESTS_FAILED"
    echo "  ⚠ Warned: $TESTS_WARNED"
    echo ""

    if (( TESTS_FAILED > 0 )); then
        echo "Result: FAILED"
        echo ""
        return 1
    elif (( TESTS_WARNED > 0 )); then
        echo "Result: PASSED (with warnings)"
        echo ""
        return 0
    else
        echo "Result: PASSED"
        echo ""
        return 0
    fi
}

# Main execution
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  Ubuntu Bootstrap - Self-Test Harness v4.0.4"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    test_syntax_check
    test_help_version
    test_dry_run_profiles
    test_health_checker
    test_print_plan
    test_doctor_mode
    test_debug_trace
    test_bundle

    print_summary
}

main "$@"
