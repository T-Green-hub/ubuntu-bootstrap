# Quick Start: Fresh Ubuntu Install on ThinkPad T14s Gen 2

## Your Hardware
- **ThinkPad T14s Gen 2** with **11th Gen Intel i7-1185G7** (Tiger Lake)
- **Intel Iris Xe Graphics**
- **Intel WiFi 6 AX201**
- **Ubuntu 24.04.3 LTS**
- **Kernel 6.14** ✓ Perfect for your hardware

---

## Step-by-Step Bootstrap

### 1. Pre-Flight Check (Recommended)
Before running bootstrap, verify your system is ready:

```bash
cd ~/ubuntu-bootstrap
sudo bash scripts/preflight_check.sh
```

This checks:
- Network connectivity
- Kernel version (needs 5.11+ for Tiger Lake)
- UEFI boot mode
- Disk space
- Hardware detection

### 2. Run Bootstrap

```bash
cd ~/ubuntu-bootstrap
./scripts/run_bootstrap.sh
```

The bootstrap will:
1. **Configure APT** (repositories, performance tuning)
2. **Install base packages** (essential tools)
3. **Install drivers** for Iris Xe, WiFi 6 AX201, audio
4. **Apply privacy hardening**
5. **Install dev tools** (optional)
6. **Optimize for T14s Gen 2** (battery thresholds, TrackPoint, fingerprint)
7. **Verify installation**

Expected runtime: **15-30 minutes** (depending on internet speed)

### 3. Reboot

```bash
sudo reboot
```

Many changes (kernel modules, udev rules, TLP) require a reboot.

---

## What Gets Optimized for Your T14s Gen 2

### Graphics (Iris Xe)
- ✓ `intel-media-va-driver-non-free` for hardware video acceleration
- ✓ Mesa Vulkan drivers for gaming/3D
- ✓ Wayland (default) recommended over X11
- ✓ VA-API for video encoding/decoding

### WiFi 6 (AX201)
- ✓ Latest firmware from `linux-firmware`
- ✓ Power management tuned for stability
- ✓ Disables aggressive power saving (prevents disconnects)

### Power Management
- ✓ TLP with 20-80% battery charge thresholds
- ✓ Extends battery lifespan significantly
- ✓ Optimized for Tiger Lake power states
- ✓ `acpi-call-dkms` for ThinkPad battery control

### TrackPoint
- ✓ Sensitivity: 200, Speed: 120 (perfect for T14s)
- ✓ Middle-button paste enabled
- ✓ Persistent via udev rules

### Other
- ✓ Fingerprint reader support (if you have one)
- ✓ Bluetooth
- ✓ Intel microcode updates
- ✓ ThinkFan (optional manual config)
- ✓ Fn-key detection

---

## Common Issues & Quick Fixes

### Issue: Graphics sluggish or screen tearing
```bash
# Verify Iris Xe drivers installed
dpkg -l | grep intel-media-va-driver-non-free

# Test hardware acceleration
vainfo  # Should show "iHD" driver for Tiger Lake

# If on X11 (check with: echo $XDG_SESSION_TYPE)
# Switch to Wayland at login screen (click gear icon)
```

### Issue: WiFi drops frequently
```bash
# Check if AX201 optimization applied
cat /etc/modprobe.d/iwlwifi-ax201.conf

# Should show: options iwlwifi power_save=0

# If missing, bootstrap will create it
# Reboot after bootstrap completes
```

### Issue: No sound
```bash
# Restart audio (PipeWire)
systemctl --user restart pipewire pipewire-pulse

# Test
speaker-test -c 2 -t wav -l 1
```

### Issue: Battery draining too fast
```bash
# Verify TLP active
sudo tlp-stat -b

# Check thresholds (should show 20/80)
cat /sys/class/power_supply/BAT0/charge_start_threshold
cat /sys/class/power_supply/BAT0/charge_stop_threshold

# Monitor power usage
sudo powertop
```

### Issue: Bootstrap fails with APT lock
```bash
# Kill background updates
sudo killall apt apt-get dpkg unattended-upgrade

# Clean locks
sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock

# Reconfigure dpkg
sudo dpkg --configure -a

# Retry
./scripts/run_bootstrap.sh
```

---

## Verify Everything Works

After reboot, run these tests:

```bash
# 1. Graphics (should show Iris Xe)
glxinfo | grep "OpenGL renderer"
vulkaninfo | grep "deviceName"

# 2. WiFi (should show connected)
nmcli device status

# 3. Audio (should hear test sound)
speaker-test -c 2 -t wav -l 1

# 4. Battery thresholds (should show 20 and 80)
cat /sys/class/power_supply/BAT0/charge_*_threshold

# 5. TLP active
systemctl status tlp.service

# 6. Bluetooth
systemctl status bluetooth.service

# 7. TrackPoint settings
find /sys/devices/platform/i8042 -name sensitivity -exec cat {} \;
# Should show: 200
```

---

## Selective Installation

Skip sections if you don't need them:

```bash
# Skip privacy hardening
./scripts/run_bootstrap.sh --skip-script=30

# Skip dev tools
./scripts/run_bootstrap.sh --skip-script=40

# Skip optional features (ProtonVPN, Brave, etc.)
./scripts/run_bootstrap.sh --skip-script=60
```

---

## Advanced: Install Only Dev Tools

If you already ran the base bootstrap and just want dev tools:

```bash
# Install specific tools
cd ~/ubuntu-bootstrap
sudo bash scripts/40_dev-tools.sh docker nodejs python

# Or all tools:
sudo bash scripts/40_dev-tools.sh all
```

Available tools: `docker`, `nodejs`, `python`, `rust`, `go`, `vscode`, `utilities`

---

## Troubleshooting Deep Dive

For comprehensive troubleshooting specific to your T14s Gen 2:

```bash
cat ~/ubuntu-bootstrap/docs/T14S_GEN2_TROUBLESHOOTING.md
```

Covers:
- Iris Xe graphics issues (flickering, tearing, black screen)
- WiFi 6 AX201 problems (disconnects, slow speeds)
- Audio crackling/popping
- Battery threshold configuration
- Kernel version requirements
- UEFI/Secure Boot issues
- Firmware updates via fwupd
- Diagnostic commands

---

## Logs

Bootstrap creates logs here:
```bash
ls -la ~/ubuntu-bootstrap/logs/
```

Each script gets its own log file. Check these if something fails.

---

## Need Help?

1. **Run pre-flight check**: `sudo bash scripts/preflight_check.sh`
2. **Check docs**: `cat docs/T14S_GEN2_TROUBLESHOOTING.md`
3. **Run system detection**: `sudo bash scripts/detect_system.sh`
4. **Check logs**: `~/ubuntu-bootstrap/logs/<timestamp>/`
5. **Report issue**: https://github.com/T-Green-hub/ubuntu-bootstrap/issues

---

## Your System is Optimal ✓

With kernel 6.14, you have excellent hardware support for:
- ✓ Intel Iris Xe Graphics (full acceleration)
- ✓ WiFi 6 AX201 (stable, no firmware issues)
- ✓ Tiger Lake power management (s2idle suspend)
- ✓ Audio (PipeWire with Tiger Lake HD Audio)

The bootstrap is specifically tuned for your hardware. Enjoy your optimized Ubuntu! 🚀
