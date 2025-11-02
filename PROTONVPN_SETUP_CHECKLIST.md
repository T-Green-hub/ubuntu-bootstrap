# ProtonVPN Setup Checklist

## Post-Installation Configuration Steps

### ✅ Completed Automatically
- [x] ProtonVPN daemon installed and enabled
- [x] ProtonVPN GUI app installed
- [x] Auto-start on login configured (`~/.config/autostart/proton-vpn.desktop`)
- [x] IPv6 leak protection verified
- [x] DNS configuration verified

### 📋 Manual Configuration Required (GUI)

#### Step 1: Open ProtonVPN App
```bash
# App is already running - check system tray (top-right)
# Or launch manually:
protonvpn-app
```

#### Step 2: Sign In (If Not Already)
1. Enter your Proton account email
2. Enter your password
3. Complete 2FA if enabled

#### Step 3: Configure Auto-Connect
1. Click **Settings** (gear icon)
2. Go to **Connection** tab
3. Enable **"Auto-connect"**
4. Select connection option:
   - **Quick Connect** (recommended - fastest server)
   - **Last server** (reconnect to previous)
   - **Specific server** (your choice)

#### Step 4: Enable Kill Switch (CRITICAL for Security)
1. In Settings, go to **Advanced** tab
2. Enable **"Kill Switch"**
3. This prevents traffic leaks if VPN disconnects

#### Step 5: Configure System Tray Behavior
1. In Settings, go to **General** tab
2. Enable **"Start minimized"**
3. Enable **"Close to system tray"** (if available)

## Verification After Reboot

Run this script to verify everything works:

```bash
#!/bin/bash
echo "=== ProtonVPN Post-Reboot Verification ==="
echo ""

# Check daemon
echo "1. ProtonVPN Daemon:"
systemctl is-active me.proton.vpn.split_tunneling.service && echo "   ✓ Active" || echo "   ✗ Not running"
systemctl is-enabled me.proton.vpn.split_tunneling.service && echo "   ✓ Enabled" || echo "   ✗ Not enabled"
echo ""

# Check GUI autostart
echo "2. GUI Auto-Start:"
[ -f ~/.config/autostart/proton-vpn.desktop ] && echo "   ✓ Configured" || echo "   ✗ Not configured"
echo ""

# Check if VPN is connected
echo "3. VPN Connection:"
if nmcli connection show --active | grep -i proton >/dev/null; then
    echo "   ✓ Connected"
    VPNIP=$(curl -s --max-time 3 https://api.ipify.org)
    echo "   IP: $VPNIP"
else
    echo "   ✗ Not connected (check if auto-connect is enabled in GUI)"
fi
echo ""

# Check IPv6 leak protection
echo "4. IPv6 Leak Protection:"
if ip link show ipv6leakintrf0 >/dev/null 2>&1; then
    echo "   ✓ Kill switch interface active"
else
    echo "   ⚠ Kill switch interface not found (may activate on connect)"
fi
echo ""

# Check DNS
echo "5. DNS Configuration:"
resolvectl status | grep -A 1 "DNS Servers:" | head -3
echo ""

echo "=== Verification Complete ==="
echo ""
echo "If VPN is not connected:"
echo "1. Open ProtonVPN app from system tray"
echo "2. Verify Settings → Connection → Auto-connect is enabled"
echo "3. Manually connect once, then reboot again to test"
```

## Security Verification

### Check for Leaks
```bash
# Check your real IP (with VPN disconnected)
curl https://api.ipify.org

# Connect VPN, then check again
curl https://api.ipify.org

# Test DNS leak
curl https://dns.google/resolve?name=whoami.akamai.net

# Test IPv6 leak (should fail or timeout)
curl -6 --max-time 3 https://api6.ipify.org
```

### Verify Kill Switch
```bash
# Check iptables rules (after enabling kill switch)
sudo iptables -L -n -v | grep -i proton

# Check for VPN routing
ip route show | grep proton
```

## Troubleshooting

### VPN Not Auto-Connecting
1. Check if auto-connect is enabled in GUI settings
2. Verify daemon is running: `systemctl status me.proton.vpn.split_tunneling.service`
3. Check logs: `journalctl -u me.proton.vpn.split_tunneling.service -n 50`

### Kill Switch Not Working
1. Verify it's enabled in GUI (Settings → Advanced)
2. Test by disconnecting VPN - internet should be blocked
3. Check iptables: `sudo iptables -L -n`

### GUI Not Starting
1. Check if process is running: `pgrep -a protonvpn-app`
2. Launch manually: `protonvpn-app`
3. Check logs: `journalctl --user -u proton-vpn -n 50` (if service exists)

## Expected Behavior After Configuration

1. **On Boot**: ProtonVPN daemon starts automatically
2. **On Login**: GUI app starts minimized in system tray
3. **Auto-Connect**: VPN connects to configured server within 5-10 seconds
4. **Kill Switch**: If enabled, blocks all non-VPN traffic
5. **IPv6**: Protected via dummy interface (black hole routing)
6. **DNS**: Routed through ProtonVPN (10.2.0.1)

## Current Status

- **Daemon**: ✅ Running and enabled
- **GUI**: ✅ Running (PID 3619)
- **Auto-Start**: ✅ Configured
- **Auto-Connect**: ⚠️ Requires GUI configuration
- **Kill Switch**: ⚠️ Requires GUI configuration
- **IPv6 Protection**: ✅ Active (when connected)

## Next Actions

1. **NOW**: Configure auto-connect and kill switch in GUI (5 minutes)
2. **THEN**: Reboot and verify everything works
3. **FINALLY**: Run verification script above

---

**Documentation**: See `docs/PROTONVPN.md` for detailed information.
