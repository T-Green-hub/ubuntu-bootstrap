# System Detection and Hardware Compatibility

The Ubuntu Bootstrap project includes intelligent hardware detection and package compatibility checking to ensure optimal system configuration.

## Overview

The bootstrap system now includes:

1. **Hardware Detection** - Identifies CPU, GPU, wireless, battery, and peripherals
2. **Package Compatibility** - Checks for deprecated packages and suggests alternatives
3. **Version-Aware Installation** - Adapts to different Ubuntu versions automatically

## New Tools

### 1. System Detection Script

**Location:** `scripts/detect_system.sh`

**Purpose:** Comprehensive hardware detection and package recommendations

**Usage:**
```bash
# Basic scan (user permissions)
bash scripts/detect_system.sh

# Detailed scan (with sudo)
sudo bash scripts/detect_system.sh

# Show help
bash scripts/detect_system.sh --help
```

**What it detects:**
- CPU vendor and model (Intel/AMD microcode recommendations)
- GPU hardware (Intel/NVIDIA/AMD with appropriate driver suggestions)
- Wireless adapters (WiFi and Bluetooth)
- Battery and power management capabilities
- Peripherals (fingerprint readers, webcams, etc.)
- Ubuntu version and package availability

**Example output:**
```
=== CPU Information ===
  Vendor: GenuineIntel
  Model:  Intel(R) Core(TM) i5-6200U CPU @ 2.30GHz
  Cores:  4
✓ Recommended: intel-microcode

=== GPU Information ===
  GPU 1: Intel Corporation HD Graphics 520
✓ Recommended GPU packages:
  Intel GPU packages:
    - i965-va-driver (for older Intel GPUs: HD Graphics)
    - intel-media-va-driver-non-free (for newer: Gen8+)
    - mesa-vulkan-drivers
    - vulkan-tools
```

### 2. Package Compatibility Checker

**Location:** `scripts/check_package_compat.sh`

**Purpose:** Identifies deprecated packages and version-specific issues

**Usage:**
```bash
# Scan all bootstrap scripts
bash scripts/check_package_compat.sh --scan

# Check for known issues
bash scripts/check_package_compat.sh --known

# Check a specific file
bash scripts/check_package_compat.sh scripts/20_drivers-firmware.sh
```

**Known package changes:**
- Ubuntu 24.04+: `libva-intel-driver` → `i965-va-driver`
- Ubuntu 22.04+: `python` → `python3`
- Network tools: `net-tools` → `iproute2`

**Example output:**
```
Ubuntu 24.04+ specific checks:

⚠ libva-intel-driver: NOT available
  → Use: i965-va-driver instead
✓ i965-va-driver: Available (correct for 24.04)
```

## Improved Driver Installation

### GPU Detection (scripts/20_drivers-firmware.sh)

The driver installation script now automatically detects GPU vendor and installs appropriate packages:

**Intel GPUs:**
- `i965-va-driver` - For older Intel HD Graphics
- `intel-media-va-driver-non-free` - For newer Intel Gen8+
- `mesa-vulkan-drivers` - Vulkan support
- `vulkan-tools` - Testing utilities

**NVIDIA GPUs:**
- Detects and recommends using `ubuntu-drivers` for proprietary drivers
- Installs Mesa drivers as fallback

**AMD GPUs:**
- `mesa-vulkan-drivers` - Open source driver
- `mesa-va-drivers` - Video acceleration
- `vulkan-tools` - Testing utilities

**Before (hardcoded):**
```bash
readonly INTEL_GRAPHICS_PKGS=(
  mesa-vulkan-drivers
  libva-intel-driver  # ❌ Doesn't exist in Ubuntu 24.04
  intel-media-va-driver-non-free
  vulkan-tools
)
```

**After (adaptive):**
```bash
# Detect GPU vendor and install appropriate drivers
if [[ "$gpu_info" =~ Intel ]]; then
    log "Intel GPU detected, installing Intel graphics drivers…"
    pkgs_to_install+=("${INTEL_GRAPHICS_PKGS[@]}")
elif [[ "$gpu_info" =~ NVIDIA ]]; then
    log "NVIDIA GPU detected..."
    # Install appropriate drivers
fi
```

## Version Compatibility

### Ubuntu 24.04 (Noble Numbat) Changes

1. **Graphics Drivers:**
   - ❌ `libva-intel-driver` (deprecated)
   - ✅ `i965-va-driver` (replacement)

2. **Python:**
   - Default: Python 3.12+
   - `python3-pip` available

3. **System Tools:**
   - Modern package names used throughout

### Ubuntu 22.04 (Jammy Jellyfish)

- Most packages remain compatible
- Both old and new package names available
- Gradual transition period

### Ubuntu 20.04 (Focal Fossa)

- Consider upgrading to newer LTS
- Some packages may be outdated
- Limited support for newer hardware

## Testing the Changes

### 1. Run System Detection

```bash
# See what hardware you have
bash scripts/detect_system.sh
```

### 2. Check Package Compatibility

```bash
# Verify all packages are available
bash scripts/check_package_compat.sh --known
```

### 3. Test Driver Installation

```bash
# Preview what would be installed
DRY_RUN=1 bash scripts/20_drivers-firmware.sh

# Actually install
bash scripts/20_drivers-firmware.sh
```

### 4. Verify Installation

```bash
# Check if drivers loaded correctly
lsmod | grep -E "i915|nouveau|amdgpu"

# Check Vulkan
vulkaninfo --summary

# Check video acceleration
vainfo
```

## Integration with Bootstrap

The system detection runs automatically during bootstrap but can be run independently:

```bash
# Full bootstrap (includes detection)
make run

# Just detection
bash scripts/detect_system.sh

# Check compatibility before running
bash scripts/check_package_compat.sh --known
```

## Benefits

1. **Prevents Installation Failures** - Detects missing packages before attempting install
2. **Hardware-Specific Optimization** - Installs only relevant drivers
3. **Version Awareness** - Adapts to different Ubuntu releases
4. **User Visibility** - Clear reporting of what was detected
5. **Maintenance** - Easy to identify and fix compatibility issues

## Future Enhancements

Potential improvements for the detection system:

1. **Automatic Fixes** - Auto-update deprecated package names
2. **Hardware Profiles** - Save and reuse detection results
3. **Performance Tuning** - Suggest optimal settings based on hardware
4. **Driver Testing** - Verify drivers work after installation
5. **Upgrade Advisor** - Recommend Ubuntu version upgrades

## Troubleshooting

### Issue: Package not found

**Solution:**
```bash
# Check what's available
bash scripts/check_package_compat.sh --known

# Update package lists
sudo apt update

# Check if repositories are enabled
grep -r "universe\|multiverse" /etc/apt/sources.list*
```

### Issue: Wrong drivers installed

**Solution:**
```bash
# Re-run detection
bash scripts/detect_system.sh

# Manually specify hardware profile
HARDWARE_PROFILE=generic bash scripts/50_laptop.sh
```

### Issue: Compatibility checker reports false positives

**Solution:**
```bash
# Check package availability manually
apt-cache show <package-name>

# Update the compatibility mappings in check_package_compat.sh
```

## Contributing

To add new hardware detection or package mappings:

1. Edit `scripts/detect_system.sh` for new hardware detection
2. Edit `scripts/check_package_compat.sh` for package mappings
3. Test on multiple Ubuntu versions
4. Submit pull request with test results

## See Also

- [Hardware Profiles](HARDWARE_PROFILES.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Installation Guide](INSTALL.md)
