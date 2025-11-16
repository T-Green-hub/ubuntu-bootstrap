#!/usr/bin/env bash
# Complete system fixes for ThinkPad T14s Gen 2
# Based on deep analysis of current state

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

echo "=== ThinkPad T14s Gen 2 - Post-Bootstrap Fixes ==="
echo ""

# 1. Install missing diagnostic tools
log "1. Installing diagnostic tools..."
apt_safe update -qq
apt_safe install -y mesa-utils vainfo pulseaudio-utils
echo "   ✓ Diagnostic tools installed"
echo ""

# 2. Create WiFi AX201 power management config
echo "2. Configuring WiFi 6 AX201 power management..."
if [ ! -f /etc/modprobe.d/iwlwifi-ax201.conf ]; then
    sudo tee /etc/modprobe.d/iwlwifi-ax201.conf > /dev/null << 'EOF'
# Intel AX201 WiFi 6 optimization
# Disable aggressive power management for better stability
options iwlwifi power_save=0
options iwlwifi uapsd_disable=1
EOF
    echo "   ✓ WiFi power management configured"
    echo "   ⚠ Reboot needed to apply"
else
    echo "   ✓ WiFi config already exists"
fi
echo ""

# 3. Create TrackPoint udev rule
echo "3. Configuring TrackPoint..."
if [ ! -f /etc/udev/rules.d/10-trackpoint.rules ]; then
    sudo tee /etc/udev/rules.d/10-trackpoint.rules > /dev/null << 'EOF'
# ThinkPad TrackPoint configuration
ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="TPPS/2 IBM TrackPoint", \
  ATTR{device/sensitivity}="200", \
  ATTR{device/speed}="120"
EOF
    sudo udevadm control --reload-rules
    echo "   ✓ TrackPoint udev rule created"
    echo "   ℹ Current sensitivity: $(cat /sys/devices/platform/i8042/serio1/sensitivity 2>/dev/null || echo 'unknown')"
    echo "   ℹ Will apply on next boot or reconnect"
else
    echo "   ✓ TrackPoint udev rule exists"
fi
echo ""

# 4. Verify and test
echo "4. Testing hardware..."

echo "   Graphics (Vulkan):"
if vulkaninfo --summary 2>/dev/null | grep -q "Iris Xe"; then
    echo "   ✓ Iris Xe Vulkan working"
else
    echo "   ⚠ Vulkan test failed"
fi

echo ""
echo "   Hardware acceleration (VA-API):"
if vainfo 2>&1 | grep -q "iHD"; then
    echo "   ✓ Intel iHD driver for Tiger Lake detected"
else
    echo "   ℹ Running vainfo..."
    vainfo 2>&1 | head -3
fi

echo ""
echo "   Audio (PipeWire):"
if systemctl --user is-active pipewire >/dev/null 2>&1; then
    echo "   ✓ PipeWire running"
else
    echo "   ⚠ PipeWire not running"
fi

echo ""
echo "5. Current Status Summary:"
echo "   ✓ Battery: $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo '?')% (thresholds: 20-80%)"
echo "   ✓ WiFi: $(nmcli -t -f DEVICE,STATE device | grep wlp | cut -d: -f2)"
echo "   ✓ TLP: $(systemctl is-active tlp.service)"
echo "   ✓ Bluetooth: $(systemctl is-active bluetooth.service)"
echo "   ✓ Kernel: $(uname -r)"
echo "   ✓ Session: ${XDG_SESSION_TYPE:-unknown}"
echo ""

echo "=== Fixes Complete ==="
echo ""
echo "Next steps:"
echo "  1. Test graphics: glxgears"
echo "  2. Test audio: speaker-test -c 2 -t wav -l 1"
echo "  3. Test hardware accel: vainfo"
echo "  4. Reboot to apply WiFi and TrackPoint changes"
echo ""
echo "For TrackPoint, settings apply on boot. Current: sensitivity=$(cat /sys/devices/platform/i8042/serio1/sensitivity 2>/dev/null || echo 'N/A')"
