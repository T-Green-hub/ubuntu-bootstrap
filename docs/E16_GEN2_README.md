# Ubuntu LTS Bootstrap for ThinkPad E16 Gen2

Canonical Ubuntu LTS post-install bootstrap for **Lenovo ThinkPad E16 Gen2 (AMD Ryzen 7)**. Safe, idempotent, evidence-based system setup.

## Features

- ✅ **Hardware-agnostic detection** - Works on E16 Gen2, T14, and other systems
- 🔒 **Safe by default** - No disk partitioning, no bootloader changes
- 🔄 **Idempotent** - Safe to re-run multiple times
- 📊 **Evidence-based** - Detailed logs and reports
- 🎯 **Profile-based** - Minimal, dev, or secure configurations
- 🔍 **Health checking** - Comprehensive read-only verification

## Quick Start

### Fresh Ubuntu LTS Install

```bash
# 1. Clone the repository
git clone https://github.com/YOUR-USERNAME/ubuntu-bootstrap.git
cd ubuntu-bootstrap

# 2. Run bootstrap (minimal profile, dry-run first)
bash scripts/bootstrap.sh --profile minimal --dry-run

# Or use interactive mode
bash scripts/bootstrap.sh --interactive

# Or preview the execution plan
bash scripts/bootstrap.sh --profile minimal --print-plan

# 3. Run for real
bash scripts/bootstrap.sh --profile minimal --yes

# 4. Verify system health
bash scripts/checks/bootstrap_check.sh

# 5. Run doctor mode for extended checks
bash scripts/checks/bootstrap_check.sh --doctor
```

## Profiles

### Minimal (Recommended for all users)
Safe baseline after fresh install:
- ✅ System updates (apt update/upgrade)
- ✅ Firmware updates (fwupd)
- ✅ CPU microcode (amd64-microcode for Ryzen)
- ✅ Drivers (linux-firmware, auto-detect GPU)
- ✅ Power management (power-profiles-daemon)
- ✅ Security baseline (ufw, unattended-upgrades)

```bash
bash scripts/bootstrap.sh --profile minimal
```

### Dev (For developers)
Minimal + development tools:
- ✅ All minimal profile features
- ✅ build-essential, git, curl, wget
- ✅ Python (python3-venv, pipx, pip)
- ✅ Node.js (Ubuntu default version + npm)
- ✅ Utilities (jq, vim, tmux, htop)

```bash
bash scripts/bootstrap.sh --profile dev
```

### Secure (For security-conscious users)
Minimal + security hardening:
- ✅ All minimal profile features
- ✅ fail2ban (optional, prompted)
- ✅ auditd (optional, prompted)
- ✅ Backup tools guidance (Timeshift/restic)
- ✅ sysctl hardening guidance

```bash
bash scripts/bootstrap.sh --profile secure
```

## Command Reference

### Bootstrap

```bash
# Show help
bash scripts/bootstrap.sh --help

# Interactive mode (guided setup)
bash scripts/bootstrap.sh --interactive

# Print execution plan (preview without running)
bash scripts/bootstrap.sh --profile minimal --print-plan

# Dry-run (preview changes without making them)
bash scripts/bootstrap.sh --profile minimal --dry-run

# Run with specific profile
bash scripts/bootstrap.sh --profile dev --yes

# Debug mode with trace logging
bash scripts/bootstrap.sh --profile minimal --dry-run --debug --trace

# Doctor mode (preflight checks)
bash scripts/bootstrap.sh --doctor

# Custom log directory
bash scripts/bootstrap.sh --profile minimal --log-dir /tmp/bootstrap-logs
```

### Health Check

```bash
# Run full health check
bash scripts/checks/bootstrap_check.sh

# Save to custom directory
bash scripts/checks/bootstrap_check.sh --output-dir /tmp/health-checks

# Doctor mode with extended checks
bash scripts/checks/bootstrap_check.sh --doctor

# Create bundle archive
bash scripts/checks/bootstrap_check.sh --doctor --bundle

# JSON output only
bash scripts/checks/bootstrap_check.sh --json > health.json
```

### Post-Install Follow-Up
- Review the targeted post-install guide for the E16 Gen2: [docs/POST_INSTALL_E16_GEN2.md](docs/POST_INSTALL_E16_GEN2.md)

### CLI Installation (Optional)

```bash
# Install ubuntu-bootstrap command to ~/.local/bin
bash scripts/install.sh

# Then use system-wide
ubuntu-bootstrap --help
ubuntu-bootstrap --interactive

# Uninstall
bash scripts/install.sh --uninstall
```

## ThinkPad E16 Gen2 Specifics

### Hardware Profile
- **CPU**: AMD Ryzen 7 (Zen 3+ architecture)
- **GPU**: AMD Radeon iGPU (open-source drivers)
- **WiFi**: Realtek or MediaTek (depends on configuration)
- **Storage**: NVMe SSD (PCIe 4.0)
- **Display**: 16" WUXGA (1920x1200) or WQXGA (2560x1600)

### What Bootstrap Does
1. **AMD Microcode**: Installs `amd64-microcode` for CPU updates
2. **AMD GPU**: Uses built-in open-source drivers (no proprietary driver needed)
3. **Firmware**: Updates via fwupd/LVFS (BIOS, firmware)
4. **Power**: Configures power-profiles-daemon (balanced/performance/power-saver)
5. **Battery**: Documents charge threshold setup (if supported)

### Battery Charge Threshold
To extend battery life, set charge limit to 80%:

```bash
# Check if supported
ls /sys/class/power_supply/BAT*/charge_control_end_threshold

# Set threshold (80%)
echo 80 | sudo tee /sys/class/power_supply/BAT*/charge_control_end_threshold

# Make persistent (add to /etc/rc.local or systemd service)
```

### Firmware Updates
```bash
# Check for firmware updates
sudo fwupdmgr refresh
sudo fwupdmgr get-updates

# Apply updates
sudo fwupdmgr update
```

## Safety Notes

### What Bootstrap Does NOT Do
- ❌ **No disk partitioning** - Does not touch /dev/*, no fdisk/parted
- ❌ **No bootloader changes** - Does not modify GRUB or UEFI entries
- ❌ **No Secure Boot requirement** - Works with Secure Boot on or off
- ❌ **No desktop environment changes** - Works with GNOME, KDE, XFCE, or headless
- ❌ **No snap removal** - Keeps Ubuntu defaults

### Safety Features
- ✅ **Idempotent** - Safe to re-run, checks before installing
- ✅ **Dry-run mode** - Preview changes before applying
- ✅ **Detailed logs** - All actions logged to `~/bootstrap-logs/`
- ✅ **Non-destructive** - Only installs packages, enables services
- ✅ **Privilege escalation** - Only uses sudo where required

## Troubleshooting

### Common Issues

#### 1. WiFi Not Working
```bash
# Check WiFi adapter
lspci | grep -i network

# For Realtek adapters
sudo apt install rtl8xxxu-dkms

# For MediaTek adapters
sudo apt install linux-firmware
```

#### 2. Suspend/Resume Issues
```bash
# Check journal for errors
sudo journalctl -b -p err | grep -i suspend

# Try updating firmware
sudo fwupdmgr refresh
sudo fwupdmgr update

# Check kernel parameters
cat /proc/cmdline
```

#### 3. Screen Brightness
```bash
# Install brightnessctl
sudo apt install brightnessctl

# Adjust brightness
brightnessctl set 50%
```

#### 4. Touchpad Issues
```bash
# Check libinput
sudo apt install libinput-tools

# Test touchpad
libinput debug-events
```

#### 5. Audio Issues
```bash
# Check sound devices
aplay -l

# Restart PulseAudio/PipeWire
systemctl --user restart pipewire
```

### Firmware Troubleshooting
```bash
# Check fwupd service
systemctl status fwupd

# Check supported devices
fwupdmgr get-devices

# Check LVFS metadata
fwupdmgr refresh --force
```

### Power Management Troubleshooting
```bash
# Check power profiles
powerprofilesctl list

# Check current profile
powerprofilesctl get

# Set profile
powerprofilesctl set power-saver
```

## Expected Output

### Bootstrap Success
```
═══════════════════════════════════════════════════════════
  BOOTSTRAP RESULT
═══════════════════════════════════════════════════════════

  ✓ PASS:    8
  ⚠ WARN:    0
  ✗ FAIL:    0

Details:
───────────────────────────────────────────────────────────
  ✓ System snapshot created
  ✓ APT updated and cleaned
  ✓ Firmware up to date
  ✓ AMD microcode installed
  ✓ AMD GPU drivers (built-in)
  ✓ Power profiles daemon active
  ✓ UFW firewall enabled
  ✓ Unattended upgrades configured

═══════════════════════════════════════════════════════════
```

### Health Check Success
```
═══════════════════════════════════════════════════════════
  HEALTH CHECK RESULT
═══════════════════════════════════════════════════════════

  ✓ PASS:   10
  ⚠ WARN:    0
  ✗ FAIL:    0

Details:
───────────────────────────────────────────────────────────
  ✓ No pending updates
  ✓ Firmware up to date
  ✓ Secure Boot disabled
  ✓ TPM present
  ✓ Disk SMART health OK
  ✓ No journal errors
  ✓ ufw active
  ✓ unattended-upgrades active
  ✓ Temperature normal
  ✓ Disk space OK (45%)

═══════════════════════════════════════════════════════════
```

## Advanced Usage

### Custom Hardware Profiles
The existing hardware profiles in `hardware/` can be used for specific optimizations:

```bash
# For ThinkPad T14
source hardware/thinkpad-t14.sh

# For HP laptops
source hardware/hp-laptop-15.sh

# For generic systems
source hardware/generic.sh
```

### Development Modules
Additional dev tools available in `scripts/dev-modules/`:

```bash
# Docker
bash scripts/dev-modules/docker.sh

# Go
bash scripts/dev-modules/go.sh

# Rust
bash scripts/dev-modules/rust.sh

# VS Code
bash scripts/dev-modules/vscode.sh
```

### Optional Features
```bash
# ProtonVPN
bash scripts/optional-features/protonvpn.sh

# Brave Browser
bash scripts/optional-features/brave.sh

# Timeshift (backups)
bash scripts/optional-features/timeshift.sh
```

## System Requirements

- **OS**: Ubuntu 24.04 LTS (Noble) or 22.04 LTS (Jammy)
- **Architecture**: x86_64 (amd64)
- **Network**: Internet connection required
- **Disk**: 20+ GB free space recommended
- **Memory**: 4+ GB RAM recommended

## Supported Hardware

### Primary Target
- Lenovo ThinkPad E16 Gen2 (AMD Ryzen 7)

### Also Tested On
- Lenovo ThinkPad T14s Gen 2 (Intel 11th gen)
- Lenovo ThinkPad T14 Gen 1 (AMD/Intel)
- HP Laptop 15 (various configs)
- Generic desktop systems

### Detection Features
- Auto-detects CPU vendor (AMD/Intel)
- Auto-detects GPU (AMD/Intel/NVIDIA)
- Auto-detects laptop vs desktop
- Auto-detects manufacturer and model

## Contributing

This is an evidence-based bootstrap toolkit. Any changes must:
1. Be idempotent and safe to re-run
2. Include syntax checks (`bash -n`)
3. Pass shellcheck (if available)
4. Be tested in dry-run mode
5. Not perform destructive operations

## License

See [LICENSE](../LICENSE) file.

## Resources

- [Ubuntu Packages](https://packages.ubuntu.com/)
- [Linux Firmware](https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git)
- [LVFS (Firmware)](https://fwupd.org/)
- [AMD Microcode](https://www.amd.com/en/support/kb/faq/pa-150)
- [ThinkPad Support](https://support.lenovo.com/)

## Next Steps After Bootstrap

1. **Reboot** if kernel or firmware was updated
2. **Run health check**: `bash scripts/checks/bootstrap_check.sh`
3. **Install optional software**: Development tools, browsers, media players
4. **Configure backups**: Timeshift (GUI) or restic (CLI)
5. **Set up development environment**: Docker, language runtimes, IDEs
6. **Customize**: Dotfiles, shell, editor preferences

---

**Questions?** Check existing documentation in `docs/` or file an issue.
