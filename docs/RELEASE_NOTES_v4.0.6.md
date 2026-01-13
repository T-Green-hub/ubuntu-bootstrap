# Ubuntu Bootstrap v4.0.6 - Release Notes

**Release Date:** January 13, 2026
**Git Commit:** 7df0c5a4317afeb8b99e4d61779df6cbd9c640ab
**Tag:** v4.0.6
**Status:** Production Ready

---

## What's New in v4.0.6

This release fixes a **critical production bug** that prevented real bootstrap runs from completing. The issue was traced to the `apt_safe()` function in `scripts/lib/package.sh`, where arithmetic loop increments (`((attempt++))`) were incompatible with `set -euo pipefail` mode, causing immediate exit before any apt operations could execute.

**Key fixes:**
- **APT Operations Fixed**: Replaced `((attempt++))` with `attempt=$((attempt + 1))` in `apt_safe()` function to prevent spurious exit code 1
- **Production Verified**: Real bootstrap runs now complete successfully with full apt update/upgrade/autoremove functionality
- **Comprehensive Testing**: All 43 self-tests pass, including dry-run and real-run verification gates

This is a **stable production release** suitable for use on bare-metal Ubuntu 24.04 LTS systems.

---

## Release Evidence

All testing artifacts are available locally as tarballs (not tracked in git due to size). These bundles contain complete execution logs, system snapshots, and verification reports.

### Evidence Artifacts

| Artifact | SHA-256 | Summary |
|----------|---------|---------|
| **Base Evidence** | `e0327751dd4bbfaa654d6698236aa3ee0d3ed90f343dbfc87c2a6fae74da60ee` | PASS=11 WARN=1 FAIL=0 |
| `proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz` | | |
| **Addendum Evidence** | `9d87a4cfb471dd9c8434a1d4449a5a3b2327fe04b7dc20d622410ede7cf869ff` | PASS=12 WARN=0 FAIL=0 |
| `proof/bundles/bootstrap_ship_20260113T091324Z_addendum_20260113T140121Z.tar.gz` | | |
| **Final Packet** | `b184116a7d306e19dc485ae98671497d18a90b9a29af9b27890b9c05e6b131c3` | Combined evidence + release marker |
| `proof/bundles/bootstrap_ship_20260113T091324Z_FINAL_20260113T140706Z.tar.gz` | | |

### Verification Results

**Base Evidence Run** (Initial testing):
- Total Checks: 12
- Passed: 11
- Warnings: 1 (expected: pending package updates)
- Failed: 0

**Addendum Evidence Run** (Post-fix validation):
- Total Checks: 12
- Passed: 12
- Warnings: 0
- Failed: 0

**Improvement:** 100% pass rate achieved after apt_safe fix.

---

## How to Verify

### Verify Checksum Integrity

```bash
# Verify base evidence bundle
echo "e0327751dd4bbfaa654d6698236aa3ee0d3ed90f343dbfc87c2a6fae74da60ee  proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz" | sha256sum -c

# Verify addendum evidence bundle
echo "9d87a4cfb471dd9c8434a1d4449a5a3b2327fe04b7dc20d622410ede7cf869ff  proof/bundles/bootstrap_ship_20260113T091324Z_addendum_20260113T140121Z.tar.gz" | sha256sum -c

# Verify final packet
echo "b184116a7d306e19dc485ae98671497d18a90b9a29af9b27890b9c05e6b131c3  proof/bundles/bootstrap_ship_20260113T091324Z_FINAL_20260113T140706Z.tar.gz" | sha256sum -c
```

### Automated Verification Script

```bash
# Run comprehensive verification
bash scripts/release/verify_release_assets.sh

# Expected output:
# ✓ Base evidence bundle checksum verified
# ✓ Addendum evidence bundle checksum verified
# ✓ Final packet checksum verified
# ✓ Base evidence results: PASS=11 WARN=1 FAIL=0
# ✓ Addendum evidence results: PASS=12 WARN=0 FAIL=0
# All verifications passed.
```

### Inspect Bundle Contents

```bash
# List base evidence files
tar -tzf proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz | head -20

# Extract and review critical files
tar -xzf proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz \
  bootstrap_ship_20260113T091324Z/real_run_sanity.txt \
  bootstrap_ship_20260113T091324Z/bootstrap.log \
  bootstrap_ship_20260113T091324Z/report.json

# View results
cat bootstrap_ship_20260113T091324Z/report.json | python3 -m json.tool | grep -E "status|test_name"
```

---

## Installation

### Quick Start (Dry-Run)
```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
git checkout v4.0.6
bash scripts/bootstrap.sh --profile minimal --dry-run
```

### Production Use (Apply Changes)
```bash
# Review what will be done
bash scripts/bootstrap.sh --profile minimal --dry-run

# Apply changes (requires sudo)
bash scripts/bootstrap.sh --profile minimal --yes

# Verify health
bash scripts/checks/bootstrap_check.sh
```

---

## Changes in This Release

### Fixed
- **Critical:** `apt_safe()` arithmetic increment now compatible with `set -euo pipefail` (scripts/lib/package.sh)
- **Critical:** Real bootstrap runs now complete successfully with apt operations fully functional

### Verified
- All 43 self-tests pass (0 failures)
- Dry-run verification gate: PASS
- Real-run verification gate: PASS (critical production test)
- Health checker: 12/12 checks PASS

### Documentation
- Added comprehensive testing evidence in proof/bundles/
- Documented verification procedures
- Updated APT_SAFE_FIX_v4_0_6.md with root cause analysis

---

## Known Limitations

- Tarballs in `proof/bundles/` are **not tracked in git** (intentionally excluded via .gitignore)
- Evidence bundles are available as GitHub Release assets for this tag
- Some health checks require elevated privileges (documented in output)

---

## Upgrade Notes

This is a **critical bug fix release**. Users of v4.0.5 or earlier should upgrade immediately if they experienced:
- Bootstrap hanging after "Updating package cache..."
- Silent failures with exit code 1
- APT operations not executing despite no error messages

No configuration changes are required. Simply pull the latest tag and re-run bootstrap.

---

## Credits

- Root cause analysis: Traced arithmetic expansion exit codes with `set -e` interaction
- Fix verification: Multi-gate testing (syntax, self-test, dry-run, real-run)
- Evidence collection: Automated bundle generation with timestamped artifacts

---

## Links

- **Repository:** https://github.com/T-Green-hub/ubuntu-bootstrap
- **Issues:** https://github.com/T-Green-hub/ubuntu-bootstrap/issues
- **Documentation:** [docs/](https://github.com/T-Green-hub/ubuntu-bootstrap/tree/main/docs)
- **Quick Start:** [docs/QUICK_START.md](https://github.com/T-Green-hub/ubuntu-bootstrap/blob/main/docs/QUICK_START.md)

---

**Note:** This release includes three evidence bundles totaling ~2MB. They are available as release assets and are not included in the git repository to keep clone sizes minimal.
