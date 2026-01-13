#!/usr/bin/env bash
# Release Asset Verification Script
# Ubuntu Bootstrap v4.0.6
# Verifies checksum integrity and test results of release evidence bundles

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Expected checksums (from FINAL_PACKET_READY.txt)
readonly BASE_SHA256="e0327751dd4bbfaa654d6698236aa3ee0d3ed90f343dbfc87c2a6fae74da60ee"
readonly ADDENDUM_SHA256="9d87a4cfb471dd9c8434a1d4449a5a3b2327fe04b7dc20d622410ede7cf869ff"
readonly FINAL_SHA256="b184116a7d306e19dc485ae98671497d18a90b9a29af9b27890b9c05e6b131c3"

# Paths
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly BUNDLE_DIR="$REPO_ROOT/proof/bundles"
readonly BASE_BUNDLE="$BUNDLE_DIR/bootstrap_ship_20260113T091324Z.tar.gz"
readonly ADDENDUM_BUNDLE="$BUNDLE_DIR/bootstrap_ship_20260113T091324Z_addendum_20260113T140121Z.tar.gz"
readonly FINAL_BUNDLE="$BUNDLE_DIR/bootstrap_ship_20260113T091324Z_FINAL_20260113T140706Z.tar.gz"

# Exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0

# Helper functions
log_pass() {
    echo -e "${GREEN}✓${NC} $*"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}✗${NC} $*" >&2
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_info() {
    echo -e "ℹ $*"
}

# Verify file exists
verify_file_exists() {
    local file="$1"
    local description="$2"

    if [[ ! -f "$file" ]]; then
        log_fail "$description: file not found at $file"
        return 1
    fi
    return 0
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local expected="$2"
    local description="$3"

    if ! verify_file_exists "$file" "$description"; then
        return 1
    fi

    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')

    if [[ "$actual" == "$expected" ]]; then
        log_pass "$description checksum verified"
        return 0
    else
        log_fail "$description checksum mismatch"
        log_info "  Expected: $expected"
        log_info "  Actual:   $actual"
        return 1
    fi
}

# Extract and verify test results from base evidence
verify_base_results() {
    local bundle="$1"
    local extract_dir
    extract_dir=$(mktemp -d)

    # Extract one of the real run logs that contains the final summary
    if ! tar -xzf "$bundle" -C "$extract_dir" bootstrap_ship_20260113T091324Z/logs/REAL_RUN_20260113T115503Z.log 2>/dev/null; then
        log_fail "Base evidence: could not extract real run log"
        rm -rf "$extract_dir"
        return 1
    fi

    local run_log="$extract_dir/bootstrap_ship_20260113T091324Z/logs/REAL_RUN_20260113T115503Z.log"

    if [[ ! -f "$run_log" ]]; then
        log_fail "Base evidence: real run log not found after extraction"
        rm -rf "$extract_dir"
        return 1
    fi

    # Parse results from Verification Summary section using grep (POSIX-compatible)
    local pass_count warn_count fail_count
    pass_count=$(grep -oP '✓ PASS:\s+\K\d+' "$run_log" 2>/dev/null || grep 'PASS:' "$run_log" | sed 's/.*PASS:[^0-9]*\([0-9]\+\).*/\1/' | tail -1)
    warn_count=$(grep -oP '⚠ WARN:\s+\K\d+' "$run_log" 2>/dev/null || grep 'WARN:' "$run_log" | sed 's/.*WARN:[^0-9]*\([0-9]\+\).*/\1/' | tail -1)
    fail_count=$(grep -oP '✗ FAIL:\s+\K\d+' "$run_log" 2>/dev/null || grep 'FAIL:' "$run_log" | sed 's/.*FAIL:[^0-9]*\([0-9]\+\).*/\1/' | tail -1)

    # Fallback: ensure we have numeric values
    pass_count="${pass_count:-0}"
    warn_count="${warn_count:-0}"
    fail_count="${fail_count:-0}"

    if [[ "$pass_count" == "11" && "$warn_count" == "1" && "$fail_count" == "0" ]]; then
        log_pass "Base evidence results: PASS=$pass_count WARN=$warn_count FAIL=$fail_count"
        rm -rf "$extract_dir"
        return 0
    else
        log_fail "Base evidence results unexpected: PASS=$pass_count WARN=$warn_count FAIL=$fail_count (expected: PASS=11 WARN=1 FAIL=0)"
        rm -rf "$extract_dir"
        return 1
    fi
}

# Extract and verify test results from addendum evidence
verify_addendum_results() {
    local bundle="$1"
    local extract_dir
    extract_dir=$(mktemp -d)

    if ! tar -xzf "$bundle" -C "$extract_dir" bootstrap_ship_20260113T091324Z_addendum_20260113T140121Z/report.json 2>/dev/null; then
        log_fail "Addendum evidence: could not extract report.json"
        rm -rf "$extract_dir"
        return 1
    fi

    local report_file="$extract_dir/bootstrap_ship_20260113T091324Z_addendum_20260113T140121Z/report.json"

    if [[ ! -f "$report_file" ]]; then
        log_fail "Addendum evidence: report.json not found after extraction"
        rm -rf "$extract_dir"
        return 1
    fi

    # Parse JSON using python3 (no jq dependency) - using summary field directly
    local counts
    counts=$(python3 -c "
import json
with open('$report_file') as f:
    data = json.load(f)
    summary = data.get('summary', {})
    print(f\"{summary.get('pass', 0)} {summary.get('warn', 0)} {summary.get('fail', 0)}\")
" 2>/dev/null || echo "0 0 0")

    local pass_count warn_count fail_count
    read -r pass_count warn_count fail_count <<< "$counts"

    if [[ "$pass_count" == "12" && "$warn_count" == "0" && "$fail_count" == "0" ]]; then
        log_pass "Addendum evidence results: PASS=$pass_count WARN=$warn_count FAIL=$fail_count"
        rm -rf "$extract_dir"
        return 0
    else
        log_fail "Addendum evidence results unexpected: PASS=$pass_count WARN=$warn_count FAIL=$fail_count (expected: PASS=12 WARN=0 FAIL=0)"
        rm -rf "$extract_dir"
        return 1
    fi
}

# Main verification
main() {
    echo "======================================================"
    echo "Ubuntu Bootstrap v4.0.6 - Release Asset Verification"
    echo "======================================================"
    echo ""

    log_info "Verifying checksums..."
    verify_checksum "$BASE_BUNDLE" "$BASE_SHA256" "Base evidence bundle"
    verify_checksum "$ADDENDUM_BUNDLE" "$ADDENDUM_SHA256" "Addendum evidence bundle"
    verify_checksum "$FINAL_BUNDLE" "$FINAL_SHA256" "Final packet bundle"

    echo ""
    log_info "Verifying test results..."
    verify_base_results "$BASE_BUNDLE"
    verify_addendum_results "$ADDENDUM_BUNDLE"

    echo ""
    echo "======================================================"
    if [[ $CHECKS_FAILED -eq 0 ]]; then
        log_pass "All verifications passed ($CHECKS_PASSED/$CHECKS_PASSED)"
        exit $EXIT_SUCCESS
    else
        log_fail "Some verifications failed: $CHECKS_PASSED passed, $CHECKS_FAILED failed"
        exit $EXIT_FAILURE
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
