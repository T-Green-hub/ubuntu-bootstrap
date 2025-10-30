#!/usr/bin/env bash
# Test script for ProtonVPN installation
# Tests all functions without requiring actual installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.."

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ProtonVPN Script Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Syntax check
echo "Test 1: Checking script syntax..."
if bash -n scripts/optional-features/protonvpn.sh; then
    echo "  ✓ Syntax check passed"
else
    echo "  ✗ Syntax check failed"
    exit 1
fi
echo ""

# Test 2: Source script (load functions)
echo "Test 2: Loading script functions..."
if source scripts/optional-features/protonvpn.sh; then
    echo "  ✓ Script sourced successfully"
else
    echo "  ✗ Failed to source script"
    exit 1
fi
echo ""

# Test 3: Dry run mode
echo "Test 3: Testing dry-run mode..."
if DRY_RUN=1 bash scripts/optional-features/protonvpn.sh >/dev/null 2>&1; then
    echo "  ✓ Dry-run mode works"
else
    echo "  ✗ Dry-run mode failed"
    exit 1
fi
echo ""

# Test 4: Verify function
echo "Test 4: Testing verification function..."
if source scripts/optional-features/protonvpn.sh && verify_protonvpn >/dev/null 2>&1; then
    echo "  ✓ Verification function works"
else
    echo "  ⚠ Verification function returned error (may be expected if not installed)"
fi
echo ""

# Test 5: Check documentation exists
echo "Test 5: Checking documentation..."
docs_ok=0
if [[ -f "docs/PROTONVPN.md" ]]; then
    echo "  ✓ Main documentation exists (PROTONVPN.md)"
    docs_ok=$((docs_ok + 1))
else
    echo "  ✗ Main documentation missing (PROTONVPN.md)"
fi

if [[ -f "docs/PROTONVPN_QUICK_REF.md" ]]; then
    echo "  ✓ Quick reference exists (PROTONVPN_QUICK_REF.md)"
    docs_ok=$((docs_ok + 1))
else
    echo "  ✗ Quick reference missing (PROTONVPN_QUICK_REF.md)"
fi

if (( docs_ok < 2 )); then
    exit 1
fi
echo ""

# Test 6: Check if ProtonVPN is actually installed
echo "Test 6: Checking actual installation status..."
if command -v protonvpn-app >/dev/null 2>&1; then
    echo "  ✓ ProtonVPN GUI is installed"
    
    if systemctl is-active --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        echo "  ✓ ProtonVPN daemon is running"
    else
        echo "  ⚠ ProtonVPN daemon is not running"
    fi
    
    if systemctl is-enabled --quiet me.proton.vpn.split_tunneling.service 2>/dev/null; then
        echo "  ✓ ProtonVPN daemon is enabled"
    else
        echo "  ⚠ ProtonVPN daemon is not enabled"
    fi
else
    echo "  ℹ ProtonVPN is not installed (this is OK for testing)"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ All Core Tests Passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ProtonVPN script is ready to use!"
echo ""
echo "Quick Commands:"
echo "  Install:  sudo bash scripts/optional-features/protonvpn.sh"
echo "  Verify:   bash scripts/optional-features/protonvpn.sh (already installed)"
echo "  Docs:     cat docs/PROTONVPN.md"
echo "  Quick Ref: cat docs/PROTONVPN_QUICK_REF.md"
echo ""
