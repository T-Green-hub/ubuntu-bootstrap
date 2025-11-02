#!/bin/bash
# ProtonVPN Post-Reboot Verification Script
# Run this after rebooting to verify auto-connect and kill switch

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     ProtonVPN Post-Reboot Verification Script                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check ProtonVPN Daemon
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. ProtonVPN Daemon Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet me.proton.vpn.split_tunneling.service; then
    check_pass "Daemon is running"
else
    check_fail "Daemon is not running"
    echo "   Try: sudo systemctl start me.proton.vpn.split_tunneling.service"
fi

if systemctl is-enabled --quiet me.proton.vpn.split_tunneling.service; then
    check_pass "Daemon is enabled (auto-start)"
else
    check_fail "Daemon is not enabled"
fi

echo ""

# 2. Check GUI Process
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. ProtonVPN GUI Application"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if pgrep -f protonvpn-app >/dev/null; then
    check_pass "GUI app is running"
else
    check_warn "GUI app is not running"
    echo "   This is normal if auto-start is disabled"
    echo "   Launch with: protonvpn-app"
fi

if [ -f ~/.config/autostart/proton-vpn.desktop ]; then
    check_pass "GUI auto-start is configured"
else
    check_warn "GUI auto-start not found"
fi

echo ""

# 3. Check VPN Connection
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. VPN Connection Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if nmcli connection show --active | grep -iq proton; then
    check_pass "VPN is connected"
    
    # Get connection details
    CONN_NAME=$(nmcli connection show --active | grep -i proton | awk '{print $1}')
    echo "   Connection: $CONN_NAME"
    
    # Get public IP
    echo -n "   Checking public IP... "
    VPNIP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "timeout")
    echo "$VPNIP"
    
    # Verify it's not your real IP (basic check)
    if [[ "$VPNIP" != "timeout" && "$VPNIP" != "174.227.144.219" ]]; then
        check_pass "IP is different from your real IP (VPN working)"
    else
        check_warn "Could not verify VPN IP"
    fi
else
    check_warn "VPN is NOT connected"
    echo ""
    echo "   Possible reasons:"
    echo "   • Auto-connect not configured in GUI"
    echo "   • Waiting for connection (may take 5-10 seconds after login)"
    echo "   • Network not ready yet"
    echo ""
    echo "   Actions:"
    echo "   1. Open ProtonVPN app (check system tray)"
    echo "   2. Settings → Connection → Enable 'Auto-connect'"
    echo "   3. Connect manually once, then test reboot again"
fi

echo ""

# 4. Check IPv6 Leak Protection
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. IPv6 Leak Protection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ip link show ipv6leakintrf0 >/dev/null 2>&1; then
    check_pass "Kill switch interface exists (ipv6leakintrf0)"
else
    check_warn "Kill switch interface not found"
    echo "   This interface is created when VPN connects"
fi

if nmcli connection show | grep -q "pvpn-killswitch-ipv6"; then
    check_pass "IPv6 kill switch connection configured"
else
    check_warn "IPv6 kill switch connection not found"
fi

# Test IPv6 leak
echo -n "   Testing IPv6 leak... "
if timeout 3 curl -6 -s https://api6.ipify.org >/dev/null 2>&1; then
    check_fail "IPv6 LEAK DETECTED!"
    echo "   Your IPv6 address is exposed"
else
    check_pass "No IPv6 leak (request failed as expected)"
fi

echo ""

# 5. Check DNS Configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. DNS Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DNS_INFO=$(resolvectl status | grep -A 2 "DNS Servers:" | head -4)
echo "$DNS_INFO"

if echo "$DNS_INFO" | grep -q "10.2.0.1"; then
    check_pass "Using ProtonVPN DNS (10.2.0.1)"
else
    check_warn "Not using ProtonVPN DNS"
    echo "   This is normal if VPN is not connected"
fi

echo ""

# 6. Check Kill Switch (iptables)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Kill Switch (iptables)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IPTABLES_RULES=$(sudo iptables -L -n 2>/dev/null | grep -i proton | wc -l)
if [ "$IPTABLES_RULES" -gt 0 ]; then
    check_pass "Kill switch iptables rules found ($IPTABLES_RULES rules)"
    echo "   Kill switch is ACTIVE"
else
    check_warn "No iptables rules found"
    echo "   Kill switch may not be enabled"
    echo "   Enable in GUI: Settings → Advanced → Kill Switch"
fi

echo ""

# 7. Check WireGuard Interface
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. WireGuard Interface"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ip link show proton0 >/dev/null 2>&1; then
    check_pass "WireGuard interface (proton0) exists"
    
    # Show interface IP
    PROTON_IP=$(ip addr show proton0 | grep "inet " | awk '{print $2}')
    if [ -n "$PROTON_IP" ]; then
        echo "   Interface IP: $PROTON_IP"
    fi
else
    check_warn "WireGuard interface (proton0) not found"
    echo "   This is created when VPN connects"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Verification Summary                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Summary
if nmcli connection show --active | grep -iq proton; then
    echo -e "${GREEN}✓ VPN is connected and working${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Verify kill switch is enabled (Settings → Advanced)"
    echo "  2. Test by disconnecting - internet should be blocked"
    echo "  3. Test DNS leak at: https://dnsleaktest.com"
else
    echo -e "${YELLOW}⚠ VPN is NOT connected${NC}"
    echo ""
    echo "Configuration needed:"
    echo "  1. Open ProtonVPN app (system tray or: protonvpn-app)"
    echo "  2. Sign in if needed"
    echo "  3. Go to Settings → Connection"
    echo "  4. Enable 'Auto-connect'"
    echo "  5. Select 'Quick Connect' or preferred server"
    echo "  6. Go to Settings → Advanced"
    echo "  7. Enable 'Kill Switch'"
    echo "  8. Connect manually once"
    echo "  9. Reboot and run this script again"
fi

echo ""
echo "For detailed information, see: docs/PROTONVPN.md"
echo ""
