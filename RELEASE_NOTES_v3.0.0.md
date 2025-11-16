# Ubuntu Bootstrap v3.0.0 - Release Notes

## 🚀 Major Release: User Experience Revolution + ThinkPad T14s Gen 2 Support

### Release Date: November 15, 2025

---

## 🎯 Highlights

- **🎨 Interactive Menu System** - Beautiful, user-friendly guided installation
- **💻 ThinkPad T14s Gen 2 Complete Support** - Tiger Lake (11th Gen Intel) optimizations
- **🔍 Pre-Flight System Checks** - Verify readiness before installation
- **📊 Progress Tracking** - Real-time progress bars and time estimates
- **📚 1500+ Lines of New Documentation** - Hardware-specific guides
- **🛠️ Hardware-Specific Fix Scripts** - Automated optimizations
- **✨ Zero Breaking Changes** - 100% backward compatible

---

## 🆕 New Features

### 1. Interactive Menu System ⭐ NEW
**File:** `scripts/interactive_menu.sh` (400+ lines)

A complete user-friendly interface that makes ubuntu-bootstrap accessible to everyone:

**Features:**
- 🎯 **Auto-detects hardware** (ThinkPad T14s Gen 2 gets special treatment!)
- 📊 **Colorful, intuitive interface** with clear navigation
- ⏱️ **Time estimates** for every operation (15-30 min for full bootstrap)
- 📚 **Built-in documentation browser** - view guides without leaving the menu
- 🔍 **Integrated pre-flight check** - verify system before starting
- 🎨 **Visual progress indicators** - know exactly what's happening
- ⚙️ **Selective installation** - choose base, dev tools, or optional features
- 🖥️ **Hardware-specific fixes menu** - T14s Gen 2 optimizations one click away

**Usage:**
```bash
bash scripts/interactive_menu.sh
# or
make menu
```

**Menu Options:**
1. Full Bootstrap (Complete system setup, ~15-30 min)
2. Pre-Flight Check (System readiness verification, ~1 min)
3. Base System Only (Essential packages, ~5-10 min)
4. Developer Tools (Docker, Node.js, Python, etc., ~10-20 min)
5. Optional Features (ProtonVPN, Brave, VLC, LibreOffice, ~5-15 min)
6. Hardware-Specific Fixes (ThinkPad T14s Gen 2 optimizations)
7. View Documentation (Browse all guides)
8. Dry Run (Preview without changes)

---

### 2. Pre-Flight System Check ⭐ NEW
**File:** `scripts/preflight_check.sh` (400+ lines)

Comprehensive system verification before running bootstrap:

**Checks Performed:**
- ✅ **Network connectivity** (tests 1.1.1.1, 8.8.8.8, github.com)
- ✅ **Ubuntu version** (24.04 LTS recommended, warns on older versions)
- ✅ **System architecture** (x86_64 required)
- ✅ **Kernel version** (verifies Tiger Lake support with 5.11+ for 11th gen Intel)
- ✅ **Boot mode** (UEFI recommended, shows Secure Boot status)
- ✅ **Disk space** (warns if < 10GB, recommends 20GB+)
- ✅ **APT/dpkg locks** (checks for active package managers)
- ✅ **Hardware detection** (identifies ThinkPad T14s Gen 2, Iris Xe, WiFi 6 AX201)
- ✅ **Sudo access** (verifies permissions)
- ✅ **Required tools** (bash, git, apt-get, systemctl)

**Special Hardware Detection:**
- Detects **ThinkPad T14s Gen 2** specifically
- Identifies **Intel Iris Xe (Tiger Lake)** for graphics
- Recognizes **Intel WiFi 6 AX201** for network optimizations
- Shows specific recommendations for detected hardware

**Usage:**
```bash
bash scripts/preflight_check.sh
# or
make preflight
```

**Exit Codes:**
- 0: All checks passed, system ready
- 1: Critical issues found, must fix before bootstrap

---

### 3. ThinkPad T14s Gen 2 Complete Support ⭐ NEW

Full support for **ThinkPad T14s Gen 2 with 11th Gen Intel Core i7-1185G7 (Tiger Lake)**.

#### New Documentation (1500+ lines)

**docs/T14S_GEN2_TROUBLESHOOTING.md** (900+ lines)
Comprehensive troubleshooting covering:
- Intel Iris Xe graphics issues (flickering, tearing, black screen, performance)
- WiFi 6 AX201 problems (disconnects, slow speeds, firmware)
- Audio issues (Tiger Lake HD Audio, PipeWire, crackling)
- Battery threshold configuration
- Kernel version requirements (5.11+ minimum, 6.0+ recommended)
- UEFI/Secure Boot compatibility
- Firmware updates via fwupd
- Diagnostic commands for every component
- Pre-bootstrap checklist
- Post-bootstrap verification
- Known working configuration

**docs/T14S_GEN2_QUICK_START.md** (300+ lines)
Step-by-step guide:
- Hardware profile overview
- Pre-flight checklist
- Bootstrap walkthrough with expected outcomes
- What gets optimized (graphics, WiFi, battery, TrackPoint)
- Common issues & quick fixes
- Verification commands
- Selective installation options
- Advanced configuration

**docs/T14S_GEN2_SUMMARY.md** (200+ lines)
Complete analysis:
- System assessment
- Key Tiger Lake issues addressed
- Enhancements made to bootstrap
- How to use the bootstrap
- After-bootstrap verification
- Known working configuration
- Support resources

#### New Scripts

**scripts/fix_t14s_gen2.sh** (100+ lines)
Automated fixes for T14s Gen 2:
- Installs diagnostic tools (mesa-utils, vainfo, pulseaudio-utils)
- Creates WiFi 6 AX201 power management config (persistent)
- Creates TrackPoint udev rule (sensitivity 200, speed 120)
- Tests all hardware (graphics, audio, acceleration)
- Shows complete status summary
- Clear next steps

**Usage:**
```bash
bash scripts/fix_t14s_gen2.sh
# or
make t14s-fixes
```

#### Enhanced Hardware Profile

**hardware/thinkpad-t14.sh** (Enhanced)
- Added `detect_model_specifics()` - Identifies Tiger Lake CPUs
- Kernel version check (warns if < 5.11 for Tiger Lake)
- Intel Iris Xe optimization (installs intel-media-va-driver-non-free)
- Wayland session detection (optimal for Iris Xe)
- WiFi 6 AX201 configuration (/etc/modprobe.d/iwlwifi-ax201.conf)
- Power management tuning for stability

#### Enhanced Drivers Script

**scripts/20_drivers-firmware.sh** (Enhanced)
- Tiger Lake / Iris Xe specific detection
- Distinguishes between Tiger Lake and legacy Intel GPUs
- Installs correct drivers per GPU generation:
  - Tiger Lake/Alder Lake/Raptor Lake: intel-media-va-driver-non-free
  - Legacy (HD Graphics/UHD pre-11th gen): i965-va-driver
- Adds vainfo tool for hardware acceleration testing

**Detected GPUs:**
- TigerLake-LP GT2 [Iris Xe Graphics] ✓
- Alder Lake / Raptor Lake (12th/13th gen) ✓
- Legacy Intel HD/UHD Graphics ✓

---

### 4. Progress Tracking & User Feedback ⭐ NEW

**Enhanced:** `scripts/run_bootstrap.sh`

**New Features:**
- ⏱️ **Elapsed time tracking** - Shows total time at completion
- 📊 **Progress bar** for each step - Visual feedback during execution
- 🎨 **Startup banner** - Professional appearance
- ⏰ **Time estimates** - Shows "15-30 minutes" upfront
- 📝 **Script list preview** - See what will run before starting
- 📈 **Enhanced summary** - Total time + detailed results

**Example Output:**
```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              Ubuntu Bootstrap v3.0.0                          ║
║         Complete System Setup for Ubuntu 24.04 LTS            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

Estimated time: 15-30 minutes (depending on internet speed)
Scripts to run:
  • 00_sane-apt.sh
  • 10_base-packages.sh
  • 20_drivers-firmware.sh
  ...

[========================================] 100% | Step 8/8: 99_verify.sh
=== Bootstrap Summary ===
Total time: 18m 34s
Successful: 8/8
  ✓ 00_sane-apt.sh
  ✓ 10_base-packages.sh
  ...
```

---

### 5. Enhanced Documentation

**README.md** (Major Update)
- Added **Interactive Menu** section at top (primary method)
- New **Hardware Support** section with ThinkPad T14s Gen 2 dedicated subsection
- Updated **Quick Commands** with new scripts
- Added links to new documentation
- Better organization and hierarchy
- Hardware-specific quick setup guides

**Makefile** (New Targets)
- `make menu` - Launch interactive menu
- `make preflight` - Run pre-flight checks
- `make t14s-fixes` - Apply ThinkPad T14s Gen 2 fixes

---

## 🔧 Technical Improvements

### Hardware Detection
- Model-specific identification (ThinkPad T14s Gen 2: 20WNS1VG00)
- CPU generation detection (11th Gen Intel = Tiger Lake)
- GPU specific identification (TigerLake-LP GT2 [Iris Xe])
- WiFi card detection (Intel AX201 = WiFi 6)
- Kernel version validation (5.11+ for Tiger Lake)

### Driver Improvements
- **Intel Iris Xe**: Proper driver selection (intel-media-va-driver-non-free)
- **WiFi 6 AX201**: Power management optimization (power_save=0)
- **TrackPoint**: Correct sensitivity (200) and speed (120) via udev
- **Battery**: Charge thresholds (20-80%) for lifespan extension

### User Experience
- **Visual feedback**: Colors, borders, progress bars
- **Time estimates**: Every operation shows expected duration
- **Smart guidance**: Context-aware suggestions
- **Safety first**: Pre-flight checks, dry-run mode
- **Professional**: Polished UI, clear messaging

---

## 📊 Statistics

### Codebase
- **8,677 lines** of shell script code
- **12,792 lines** of documentation
- **43** shell scripts
- **35** documentation files

### New in v3.0.0
- **+3** new scripts (interactive_menu, preflight_check, fix_t14s_gen2)
- **+3** T14s Gen 2 documentation files (1500+ lines)
- **+257** lines in modified files
- **+400** lines interactive menu
- **+400** lines pre-flight check
- **+100** lines T14s fixes

### Documentation Growth
- v2.0.0: ~11,300 lines
- v3.0.0: **12,792 lines** (+13%)
- New guides: **1,500+ lines** for T14s Gen 2

---

## 🔄 Backward Compatibility

**100% Compatible** - All existing workflows work identically:

```bash
# All existing commands still work
make run
DRY_RUN=1 make run
scripts/run_bootstrap.sh --skip-script=40
scripts/40_dev-tools.sh docker nodejs
```

**No Breaking Changes:**
- All script interfaces unchanged
- Existing automation continues working
- Optional new features, not required
- Progressive enhancement approach

---

## 📖 Usage Workflows

### For New Users (Recommended)
```bash
cd ubuntu-bootstrap
bash scripts/interactive_menu.sh
# Follow the menu guidance
```

### For ThinkPad T14s Gen 2 Users
```bash
cd ubuntu-bootstrap

# 1. Verify system
bash scripts/preflight_check.sh

# 2. Run bootstrap
make run

# 3. Apply T14s-specific fixes
bash scripts/fix_t14s_gen2.sh

# 4. Reboot
sudo reboot
```

### For Power Users (Traditional)
```bash
cd ubuntu-bootstrap

# Full bootstrap
make run

# Or selective
DRY_RUN=1 make run  # Preview first
scripts/run_bootstrap.sh --skip-script=40  # Skip dev tools
scripts/40_dev-tools.sh docker nodejs  # Specific tools only
```

---

## 🐛 Bug Fixes

None in this release - focused on new features and enhancements.

---

## 🔮 Future Enhancements

Potential improvements for v3.1.0+:
- Additional laptop profiles (Dell XPS, System76)
- More hardware-specific optimizations
- Automated recovery options
- Web-based progress dashboard
- Remote installation support

---

## 📝 Migration Guide

### From v2.x to v3.0.0

**No migration needed!** v3.0.0 is fully backward compatible.

**Optional: Try new features:**
1. Run interactive menu: `bash scripts/interactive_menu.sh`
2. Check your hardware: `bash scripts/preflight_check.sh`
3. If on T14s Gen 2: `bash scripts/fix_t14s_gen2.sh`

---

## 🙏 Acknowledgments

- Tiger Lake support based on extensive testing on ThinkPad T14s Gen 2
- Community feedback on user experience improvements
- Ubuntu 24.04 LTS compatibility testing

---

## 📞 Support

- **Documentation**: See `docs/` directory
- **T14s Gen 2**: See `docs/T14S_GEN2_QUICK_START.md`
- **Issues**: https://github.com/T-Green-hub/ubuntu-bootstrap/issues
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`

---

## 📜 License

MIT License - See LICENSE file

---

**Upgrade Command:**
```bash
cd ubuntu-bootstrap
git pull origin main
# New features available immediately!
```

**First Time Install:**
```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
bash scripts/interactive_menu.sh  # Recommended for first-timers
```

---

**Enjoy your optimized Ubuntu experience!** 🚀
