# ThinkPad T14s Gen 2 (i7-1185G7) - Troubleshooting Guide

## Hardware Profile
- **Model**: ThinkPad T14s Gen 2 (20WNS1VG00)
- **CPU**: 11th Gen Intel Core i7-1185G7 (Tiger Lake, 8 cores @ 3.00GHz)
- **GPU**: Intel Iris Xe Graphics (TigerLake-LP GT2)
- **WiFi**: Intel AX201 (WiFi 6)
- **Audio**: Tiger Lake-LP Smart Sound Technology
- **Ubuntu**: 24.04.3 LTS
- **Kernel**: 6.14.0 (or 6.8+ recommended)

---

## Common Bootstrap Issues & Solutions

### 1. **Graphics Issues (Iris Xe)**

#### Symptoms:
- Screen flickering or tearing
- Poor graphics performance
- Display not detected after boot
- Black screen on login
- Wayland session crashes

#### Root Causes:
Tiger Lake's Iris Xe requires:
- Kernel 5.11+ (you have 6.14 ✓)
- Mesa 21.0+ for proper Vulkan support
- `intel-media-va-driver-non-free` for hardware acceleration

#### Solutions:

```bash
# 1. Verify current drivers
lspci -k | grep -A 3 "VGA"
# Should show: Kernel driver in use: i915

# 2. Install complete Iris Xe driver stack
sudo apt update
sudo apt install -y \
  mesa-vulkan-drivers \
  intel-media-va-driver-non-free \
  libva-intel-driver \
  vulkan-tools \
  mesa-utils

# 3. Test Vulkan support
vulkaninfo | grep "deviceName"
# Should show: Intel(R) Xe Graphics

# 4. Test VA-API (hardware video acceleration)
sudo apt install -y vainfo
vainfo
# Should show iHD driver for Tiger Lake

# 5. If using X11 with tearing, create/edit:
sudo nano /etc/X11/xorg.conf.d/20-intel.conf
```

Add:
```conf
Section "Device"
   Identifier  "Intel Graphics"
   Driver      "intel"
   Option      "TearFree"    "true"
   Option      "AccelMethod" "sna"
   Option      "DRI"         "3"
EndSection
```

**Recommended:** Use Wayland (default in Ubuntu 24.04) instead of X11 for better Iris Xe support.

---

### 2. **WiFi 6 AX201 Issues**

#### Symptoms:
- WiFi not detected
- Frequent disconnections
- Slow speeds despite WiFi 6
- "No WiFi adapter found"

#### Root Causes:
- Intel AX201 requires recent firmware
- Power management can cause disconnects
- Missing `iwlwifi` firmware

#### Solutions:

```bash
# 1. Check WiFi hardware detection
lspci | grep -i wireless
# Should show: Intel Corporation Wi-Fi 6 AX201

# 2. Check if driver is loaded
lsmod | grep iwlwifi
# Should show: iwlwifi module

# 3. Install/update firmware
sudo apt update
sudo apt install -y linux-firmware

# 4. Check firmware version
dmesg | grep iwlwifi
# Look for: iwlwifi-ty-a0-gf-a0-XX.ucode

# 5. If firmware missing, download manually:
cd /tmp
wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/iwlwifi-ty-a0-gf-a0-73.ucode
sudo cp iwlwifi-ty-a0-gf-a0-73.ucode /lib/firmware/
sudo modprobe -r iwlwifi && sudo modprobe iwlwifi

# 6. Disable aggressive power management (if disconnecting):
sudo tee /etc/modprobe.d/iwlwifi.conf << EOF
# Disable power management for AX201 stability
options iwlwifi power_save=0
options iwlwifi uapsd_disable=1
EOF

sudo modprobe -r iwlwifi && sudo modprobe iwlwifi

# 7. Alternative: Use TLP to manage WiFi power
sudo tlp-stat -w
# Check WiFi power settings
```

---

### 3. **Audio Issues (Tiger Lake HD Audio)**

#### Symptoms:
- No sound output
- Microphone not working
- Audio crackling/popping
- "Dummy output" as only device

#### Solutions:

```bash
# 1. Check audio hardware
lspci | grep -i audio
# Should show: Tiger Lake-LP Smart Sound Technology

# 2. Check loaded modules
lsmod | grep snd_hda_intel
# Should show: snd_hda_intel module

# 3. Install PulseAudio/PipeWire tools
sudo apt install -y pavucontrol pipewire-audio

# 4. If using PulseAudio, reload:
pulseaudio -k
pulseaudio --start

# 5. If using PipeWire (default Ubuntu 24.04):
systemctl --user restart pipewire pipewire-pulse

# 6. Fix audio power management (stops crackling):
echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save

# Make permanent:
sudo tee /etc/modprobe.d/audio-powersave.conf << EOF
# Disable audio power saving to prevent crackling
options snd_hda_intel power_save=0
EOF

# 7. Update ALSA UCM (audio profiles) if needed:
sudo apt install -y alsa-ucm-conf

# 8. Test audio:
speaker-test -c 2 -t wav
```

---

### 4. **Battery & Power Management**

#### Symptoms:
- Battery drains too fast
- Laptop doesn't sleep properly
- Overheating
- Thresholds not working

#### Solutions:

```bash
# 1. Check battery threshold support
ls /sys/class/power_supply/BAT0/charge_*_threshold
# Should exist on ThinkPad T14s Gen 2

# 2. Verify TLP installation (bootstrap should do this)
sudo tlp-stat -b
# Check threshold settings

# 3. If thresholds not working, install manually:
sudo apt install -y tlp acpi-call-dkms

# 4. Configure thresholds (20-80% recommended):
sudo tee /etc/tlp.d/01-battery-thresholds.conf << EOF
START_CHARGE_THRESH_BAT0=20
STOP_CHARGE_THRESH_BAT0=80
EOF

sudo tlp start

# 5. Check sleep/suspend issues:
sudo systemctl status sleep.target
dmesg | grep -i "suspend\|acpi"

# 6. If suspend broken, try s2idle:
cat /sys/power/mem_sleep
# Should show: [s2idle] deep

# Force s2idle if needed:
sudo tee /etc/default/grub.d/sleep.cfg << EOF
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mem_sleep_default=s2idle"
EOF
sudo update-grub

# 7. Check for power-hungry processes:
sudo powertop
# Navigate to "Tunables" tab and enable all
```

---

### 5. **Kernel Version Issues**

#### Minimum Requirements:
- **Kernel 5.11+** for basic Tiger Lake support
- **Kernel 5.14+** recommended for full Iris Xe support
- **Kernel 6.0+** for best power management
- **Current: 6.14.0** ✓ Should work perfectly

#### If on older kernel:

```bash
# Check current kernel
uname -r

# If < 5.14, update via HWE stack:
sudo apt install -y --install-recommends linux-generic-hwe-24.04

# Or use mainline kernel (advanced):
sudo add-apt-repository -y ppa:cappelikan/ppa
sudo apt update
sudo apt install -y mainline
# Use GUI to install latest stable kernel
```

---

### 6. **TrackPoint Configuration**

#### The bootstrap already handles this, but if not working:

```bash
# 1. Check TrackPoint device
xinput list | grep -i trackpoint

# 2. Manual sensitivity adjustment:
find /sys/devices/platform/i8042 -name sensitivity
# Note the path, then:

echo 200 | sudo tee /sys/devices/platform/i8042/serio1/serio2/sensitivity
echo 120 | sudo tee /sys/devices/platform/i8042/serio1/serio2/speed

# 3. Verify udev rule exists:
cat /etc/udev/rules.d/10-trackpoint.rules

# 4. If missing, bootstrap will create it, or manually:
sudo tee /etc/udev/rules.d/10-trackpoint.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="TPPS/2 IBM TrackPoint", \
  ATTR{device/sensitivity}="200", \
  ATTR{device/speed}="120"
EOF

sudo udevadm control --reload-rules
```

---

### 7. **Bootstrap-Specific Issues**

#### Problem: Bootstrap fails at `00_sane-apt.sh`

**Cause:** Repository lock or network issues

**Solution:**
```bash
# 1. Check network connectivity
ping -c 3 1.1.1.1
ping -c 3 github.com

# 2. Release APT locks manually:
sudo killall apt apt-get dpkg
sudo rm -f /var/lib/dpkg/lock* /var/cache/apt/archives/lock
sudo dpkg --configure -a
sudo apt update

# 3. Retry bootstrap:
cd ~/ubuntu-bootstrap
./scripts/run_bootstrap.sh
```

#### Problem: Bootstrap fails at `20_drivers-firmware.sh`

**Cause:** Missing firmware or driver conflicts

**Solution:**
```bash
# 1. Run drivers script standalone:
cd ~/ubuntu-bootstrap
sudo bash scripts/20_drivers-firmware.sh

# 2. Check for errors:
dmesg | grep -i error | tail -20

# 3. If microcode fails:
sudo apt install -y intel-microcode
sudo update-initramfs -u
```

#### Problem: Bootstrap hangs during TLP installation

**Cause:** Battery threshold detection or DKMS compilation

**Solution:**
```bash
# 1. Skip laptop-specific config temporarily:
./scripts/run_bootstrap.sh --skip-script=50

# 2. Run laptop config manually later:
sudo bash scripts/50_laptop.sh

# 3. Check DKMS status:
sudo dkms status
# Look for acpi-call or tp-smapi build issues
```

---

### 8. **Firmware Updates**

ThinkPad T14s Gen 2 should have BIOS updated to avoid issues:

```bash
# 1. Check current BIOS version:
sudo dmidecode -s bios-version

# 2. Update via Lenovo Vantage (Windows) or:
# Download from: https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-t-series-laptops/thinkpad-t14s-gen-2-type-20wn-20wo

# 3. Use fwupd (Linux firmware updater):
sudo apt install -y fwupd
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update

# 4. Check for BIOS settings:
# - Secure Boot: Can be enabled (Ubuntu 24.04 supports it)
# - UEFI Boot: Required (not Legacy)
# - USB Boot: Enable if installing from USB
# - Thunderbolt Security: Auto or User Authorization
```

---

### 9. **UEFI/Secure Boot Issues**

#### If bootstrap fails to boot after running:

**Symptoms:**
- GRUB errors
- "Secure Boot Violation"
- System won't boot

**Solutions:**

```bash
# In rescue/live USB:

# 1. Check boot mode
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "Legacy"
# Must be UEFI for T14s Gen 2

# 2. Reinstall GRUB:
sudo mount /dev/nvme0n1pX /mnt  # Replace X with root partition
sudo mount /dev/nvme0n1p1 /mnt/boot/efi  # EFI partition
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys

sudo chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu
update-grub
exit

sudo umount -R /mnt
sudo reboot

# 3. If Secure Boot issues, sign kernel:
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
# Or disable Secure Boot in BIOS temporarily
```

---

### 10. **Diagnostic Commands**

Run these to gather info for troubleshooting:

```bash
# System Info
sudo dmidecode -s system-product-name
lscpu | grep "Model name"
uname -r

# Hardware Detection
lspci | grep -E "VGA|Network|Audio"
lsusb
sudo lshw -short

# Graphics
glxinfo | grep "OpenGL renderer"
vulkaninfo | grep "deviceName"
vainfo

# WiFi
nmcli device wifi list
sudo dmesg | grep iwlwifi

# Audio
pactl list sinks short
aplay -l

# Power
sudo tlp-stat -b
sudo powertop --html=/tmp/powertop.html

# Battery
cat /sys/class/power_supply/BAT0/capacity
cat /sys/class/power_supply/BAT0/status

# Logs
journalctl -b -p err
dmesg | grep -i "error\|fail\|warn" | tail -50

# Bootstrap logs (if exists)
ls -la ~/ubuntu-bootstrap/logs/
```

---

## Pre-Bootstrap Checklist

Before running the bootstrap on a **fresh Ubuntu install**:

### 1. **BIOS Settings** (F1 at boot)
- [ ] UEFI Boot Mode (not Legacy)
- [ ] Secure Boot: Can be enabled or disabled
- [ ] USB Boot: Enabled (for rescue)
- [ ] Thunderbolt: Auto or User Authorization
- [ ] Battery Charge Threshold: Check if BIOS has this (may conflict with TLP)

### 2. **Network Connection**
```bash
# Test before bootstrap:
ping -c 3 1.1.1.1 && ping -c 3 github.com && echo "Network OK"
```

### 3. **System Updates First**
```bash
# Update base system before bootstrap:
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo reboot
```

### 4. **Clone Bootstrap**
```bash
cd ~
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
```

### 5. **Optional: Dry Run**
```bash
# See what will be done without changes:
./scripts/run_bootstrap.sh --dry-run
```

### 6. **Run Bootstrap**
```bash
# Full run:
./scripts/run_bootstrap.sh

# Or skip problematic sections:
./scripts/run_bootstrap.sh --skip-script=60  # Skip optional features

# Monitor logs in another terminal:
tail -f logs/$(ls -t logs/ | head -1)/*.log
```

---

## Post-Bootstrap Verification

After successful bootstrap run:

```bash
# 1. Check all installed
dpkg -l | grep -E "intel-microcode|tlp|bluez|mesa-vulkan"

# 2. Verify services
systemctl status tlp.service
systemctl status bluetooth.service

# 3. Test hardware
# Graphics:
glxgears  # Should see spinning gears
# WiFi:
nmcli device status
# Audio:
speaker-test -c 2 -t wav -l 1

# 4. Reboot to apply all changes
sudo reboot
```

---

## Known Working Configuration

This exact setup **works perfectly** on T14s Gen 2:

- **OS**: Ubuntu 24.04.3 LTS
- **Kernel**: 6.8+ (6.14 confirmed working)
- **Graphics**: intel-media-va-driver-non-free + mesa 24.0+
- **WiFi**: linux-firmware with iwlwifi-ty-a0 firmware
- **Desktop**: GNOME 46 with Wayland
- **Power**: TLP with 20-80% battery thresholds
- **Audio**: PipeWire (default in 24.04)

---

## Quick Fixes Summary

| Issue | Quick Fix |
|-------|-----------|
| No graphics | `sudo apt install -y intel-media-va-driver-non-free mesa-vulkan-drivers` |
| No WiFi | `sudo apt install -y linux-firmware && sudo modprobe -r iwlwifi && sudo modprobe iwlwifi` |
| No audio | `systemctl --user restart pipewire pipewire-pulse` |
| Battery drain | `sudo apt install -y tlp && sudo tlp start` |
| Bootstrap APT lock | `sudo killall apt && sudo rm /var/lib/dpkg/lock* && sudo dpkg --configure -a` |
| Suspend broken | Add `mem_sleep_default=s2idle` to GRUB cmdline |

---

## Still Having Issues?

1. **Check logs**: `~/ubuntu-bootstrap/logs/<timestamp>/`
2. **Run system detection**: `sudo bash scripts/detect_system.sh`
3. **Test individual scripts**: `sudo bash scripts/20_drivers-firmware.sh`
4. **Gather diagnostics**: Run all commands in section 10
5. **Report issue**: https://github.com/T-Green-hub/ubuntu-bootstrap/issues

Include:
- Output of `sudo dmidecode -s system-product-name`
- Output of `uname -r`
- Output of `lspci | grep -E "VGA|Network|Audio"`
- Bootstrap log files
- Specific error messages
