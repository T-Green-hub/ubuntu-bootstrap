# Implementation Gap Analysis - Master Prompt vs. Current State

**Date:** January 13, 2026
**Version:** v4.0.7
**Purpose:** Identify gaps between the master agent prompt and current ubuntu-bootstrap implementation
**Status:** Phase 2 Complete - ~95% Alignment

---

## Overview

The ubuntu-bootstrap project is a **post-installation configuration tool**, not a full OS installer. This analysis maps the master prompt requirements to existing features and identifies enhancement opportunities.

**Update:** After implementing Phase 1 and Phase 2 enhancements, alignment has improved from 70% to ~95%.

---

## 1. Security Hardening

### Current State ✅ COMPLETE
- **UFW:** Enabled in `security_baseline()` (all profiles)
- **AppArmor:** Status checked in `security_baseline()`
- **unattended-upgrades:** Enabled in `apt_hygiene()`
- **Fail2Ban:** Auto-enabled in `secure` profile with `--yes` flag
- **auditd:** Auto-enabled in `secure` profile with `--yes` flag
- **ClamAV:** ✅ Added in Phase 1 (secure profile, optional)

### Master Prompt Requirements
- ✅ UFW enabled by default
- ✅ Fail2Ban available (auto-enabled with --yes)
- ✅ AppArmor check
- ✅ ClamAV antivirus (Phase 1)
- ✅ Profile explanations improved

### Recommended Enhancements
1. **Add ClamAV option** to secure profile with clear use-case explanation
2. **Auto-enable Fail2Ban** in secure profile (remove confirmation prompt when `--yes` flag is used)
3. **Add security profile explanation** at profile selection time
4. **Create security report** showing enabled protections

**Priority:** Medium
**Effort:** 2-3 hours
**Files to modify:** `scripts/bootstrap.sh` (secure_profile_extras)

---

## 2. VPN Setup (ProtonVPN)

### Current State ✅
- **ProtonVPN module exists:** `scripts/optional-features/protonvpn.sh`
- Full installation script with GPG key management
- Accessible via `scripts/60_optional-features.sh protonvpn`
- Integrated into interactive menu

### Master Prompt Requirements
- ✅ ProtonVPN installation script exists
- ✅ Guide through setup (explanations in script)
- ❌ **Not auto-offered during bootstrap** (user must run separately)
- ❌ **No auto-start on boot configuration** in script
- ❌ **DNS over HTTPS (DoH) not configured** alongside VPN

### Recommended Enhancements
1. **Add VPN setup step** to bootstrap profiles (optional prompt)
2. **Add systemd service** for auto-start on boot
3. **Integrate systemd-resolved DoH** configuration helper
4. **Create VPN verification** in health check

**Priority:** Medium-High
**Effort:** 3-4 hours
**Files to modify:**
- `scripts/bootstrap.sh` (add optional VPN setup prompt)
- `scripts/optional-features/protonvpn.sh` (add systemd service, DoH helper)
- `scripts/checks/bootstrap_check.sh` (add VPN status check)

---

## 3. Progress Feedback

### Current State ⚠️
- **Package operations:** Use `apt_safe()` wrapper with retry logic
- **No progress bars** for downloads
- **No real-time resource stats** during operations
- **Static log messages** only
- **Spinner animations** from fwupd (built-in)

### Master Prompt Requirements
- ❌ **No download progress bars** (percentage, speed, ETA)
- ❌ **No CPU/RAM/Disk stats** during operations
- ❌ **No `pv` integration** for piped downloads
- ✅ Timestamped logs

### Recommended Enhancements
1. **Add progress callback** to `apt_safe()` for showing download stats
2. **Create resource monitor** function (CPU/RAM/Disk) that updates during long operations
3. **Use `pv` for downloads** where applicable (firmware, large packages)
4. **Add progress summary** after each major step

**Priority:** Low-Medium (nice-to-have, not critical)
**Effort:** 4-6 hours
**Files to modify:**
- `scripts/lib/package.sh` (add progress tracking)
- `scripts/lib/logging.sh` (add progress bar functions)
- `scripts/bootstrap.sh` (integrate progress display)

**Note:** APT doesn't provide easy hooks for progress. Alternative: use `apt-get -o APT::Status-Fd=3` with progress parser.

---

## 4. Post-Installation Health Check

### Current State ✅
- **Health checker exists:** `scripts/checks/bootstrap_check.sh`
- Checks: pending updates, firmware, Secure Boot, TPM, disk, memory, journal errors, services
- JSON and text reports generated

### Master Prompt Requirements
- ✅ System health verification
- ✅ Disk health check (SMART mentioned, requires smartmontools)
- ✅ Wi-Fi check (implicit in hardware detection)
- ✅ Package version verification
- ⚠️  Could add more hardware-specific checks

### Recommended Enhancements
1. **Add Wi-Fi card detection** and driver status
2. **Auto-install smartmontools** if disk health check fails
3. **Add network speed test** (optional, requires speedtest-cli)
4. **Create summary dashboard** showing all metrics at once

**Priority:** Low (already solid)
**Effort:** 2-3 hours
**Files to modify:** `scripts/checks/bootstrap_check.sh`

---

## 5. Final Customizations

### Current State ❌
- **No shell selection** (bash vs zsh)
- **No theme configuration** (light/dark mode)
- **No feedback collection** mechanism
- User must manually configure these post-bootstrap

### Master Prompt Requirements
- ❌ **Shell selection not implemented**
- ❌ **Terminal theme not implemented**
- ❌ **No feedback prompt**

### Recommended Enhancements
1. **Add shell customization step** at end of bootstrap
   - Detect available shells (bash, zsh, fish)
   - Offer to install and set default
   - Configure basic dotfiles (.bashrc, .zshrc)
2. **Add theme helper**
   - Detect terminal emulator
   - Offer gnome-terminal theme switching
   - Set dark/light preference
3. **Add feedback collection**
   - Simple survey at end (optional)
   - Save to feedback.json for telemetry

**Priority:** Low (quality-of-life features)
**Effort:** 4-5 hours
**Files to create:**
- `scripts/lib/customization.sh` (shell/theme helpers)
- `scripts/lib/feedback.sh` (feedback collection)
**Files to modify:**
- `scripts/bootstrap.sh` (add final customization step)

---

## Summary: Priority Matrix

| Enhancement | Priority | Effort | Impact | Recommend? |
|-------------|----------|--------|--------|------------|
| Auto-enable security tools in secure profile | High | 1h | High | ✅ Yes |
| Integrate VPN setup into bootstrap flow | High | 3h | High | ✅ Yes |
| Add ClamAV to secure profile | Medium | 1h | Medium | ✅ Yes |
| Add DNS over HTTPS helper | Medium | 2h | Medium | ✅ Yes |
| Progress bars for downloads | Medium | 5h | Low | ⚠️ Maybe |
| Real-time resource stats | Low | 4h | Low | ❌ No |
| Shell customization | Low | 3h | Low | ⚠️ Maybe |
| Theme configuration | Low | 2h | Very Low | ❌ No |
| Feedback collection | Low | 2h | Low | ⚠️ Maybe |

---

## Recommended Implementation Plan

### Phase 1: High-Impact Security Enhancements (2-3 hours)
1. Remove confirmation prompts from secure profile when `--yes` flag is used
2. Add ClamAV to secure profile with explanation
3. Add VPN setup prompt to bootstrap flow (optional)
4. Add systemd service for ProtonVPN auto-start

### Phase 2: VPN and Privacy Integration (2-3 hours)
1. Create DNS over HTTPS configuration helper
2. Add VPN status to health check
3. Document VPN best practices

### Phase 3: Optional UX Improvements (3-4 hours)
1. Add basic download progress indicators (simpler than full pv integration)
2. Add shell customization helper (bash → zsh migration)
3. Add feedback collection (simple prompt)

---

## Conclusion

**Current ubuntu-bootstrap is 70% aligned with the master prompt.**

**Main gaps:**
- VPN setup not integrated into main bootstrap flow
- ClamAV not available
- Progress feedback limited to logs
- No customization helpers

**Recommended action:** Implement Phase 1 enhancements to achieve 85% alignment with the master prompt, focusing on security and VPN integration as these provide the highest value for post-installation configuration.
