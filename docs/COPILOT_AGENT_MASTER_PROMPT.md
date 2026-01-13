# COPILOT AGENT MASTER PROMPT - Ubuntu Bootstrap (v4.0.2+)

**Mode:** AUDIT → PATCH → TEST → SHIP (evidence-based only)

---

## Context

**Repository:** `~/ubuntu-bootstrap`
**Current Version:** v4.0.2
**Tag/Commit:** v4.0.2 / 677f3d1

**Key Files:**
- `scripts/bootstrap.sh` - Main orchestrator (apply profiles)
- `scripts/checks/bootstrap_check.sh` - Read-only health verifier
- `scripts/lib/version.sh` - Single source of version truth
- `docs/FINAL_TEST_OUTPUT_v4_0_2.md` - Evidence bundle

**Non-Negotiables:**
1. **Evidence-only claims** - Never say something happened unless command output proves it
2. **Read-only checker** - Must never auto-sudo or modify system state
3. **Dry-run clarity** - Must never claim installs/enables; use "would..." language
4. **Minimal changes** - Keep patches small, idempotent, and reversible
5. **Consistent versioning** - Both scripts must print identical version from central source

---

## Output Contract (Required Sections)

Return exactly these sections in order:

1. **TL;DR** (≤3 bullets)
2. **Repo Snapshot** (commands run + decisive outputs)
3. **Patch Plan** (bullets, each mapped to a file)
4. **File Edits** (exact files + full contents for any new/rewritten files)
5. **Test Commands** (copy/paste) + expected output (plain text)
6. **Ship Steps** (commit message, tag, push) + verification commands
7. **Risk Notes** (≤5 bullets)

---

## PHASE 1 — AUDIT

**Run these commands; paste decisive outputs:**

```bash
cd ~/ubuntu-bootstrap
git status -sb
git describe --tags --always
git log -1 --oneline
bash scripts/bootstrap.sh --version
bash scripts/checks/bootstrap_check.sh --version
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh
```

**Scan for issues:**

```bash
rg -n "BOOTSTRAP_VERSION|--log-dir|--output-dir|DRY-RUN" scripts/ docs/ Makefile
rg -n "installed|enabled" scripts/bootstrap.sh | rg -i "dry.?run"
```

---

## PHASE 2 — PATCH (Only if audit finds issues)

**Common Targets:**

### A) Documentation Cleanup
- Fix command path typos (e.g., `scripts/bootstrap.sh`)
- Label pre-commit vs post-push evidence blocks clearly
- Update deprecation warnings with specific version removal

### B) CI Gates
- GitHub Actions workflow: `bash -n` + `shellcheck`
- Version consistency check between both scripts
- Non-blocking shellcheck warnings

### C) UX Hardening
- Add `--print-plan` flag (show steps without executing)
- Add `--skip-step <name>` for offline or custom installs
- Do NOT break existing flags

### D) Deprecation Management
- If `--log-dir` remains, warn: "deprecated and will be removed in vX.Y.Z"
- Ensure it maps cleanly to `--output-dir`

---

## PHASE 3 — TEST (Must run and paste outputs)

```bash
# Help/version tests
bash scripts/bootstrap.sh --help
bash scripts/bootstrap.sh --version
bash scripts/checks/bootstrap_check.sh --help
bash scripts/checks/bootstrap_check.sh --version

# Syntax validation
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# Optional: Makefile lint (if make is installed)
make lint-light 2>&1 || echo "make not installed (OK)"

# Dry-run tests (all profiles)
bash scripts/bootstrap.sh --profile minimal --dry-run --output-dir /tmp/bs_test_min 2>&1 | tail -120
bash scripts/bootstrap.sh --profile dev --dry-run --output-dir /tmp/bs_test_dev 2>&1 | tail -120
bash scripts/bootstrap.sh --profile secure --dry-run --output-dir /tmp/bs_test_sec 2>&1 | tail -120

# Verify output artifacts
ls -la /tmp/bs_test_min /tmp/bs_test_dev /tmp/bs_test_sec

# Health checker test
bash scripts/checks/bootstrap_check.sh --output-dir /tmp/ck_test 2>&1 | tail -160
ls -la /tmp/ck_test
```

**Expected Results:**
- All `bash -n` checks pass
- Version strings match across both scripts
- Dry-run outputs show "DRY-RUN MODE: No system changes will be made"
- All dry-runs complete with PASS counts (no FAIL)
- Artifacts created in specified output directories

---

## PHASE 4 — SHIP (Only if tests pass)

```bash
# Stage changes
git add -A
git status --short

# Commit with descriptive message
git commit -m "vX.Y.Z: <concise summary>

- <change 1>
- <change 2>
- <change 3>

Acceptance tests:
✓ <test category 1>
✓ <test category 2>
✓ <test category 3>

Evidence: docs/FINAL_TEST_OUTPUT_vX_Y_Z.md"

# Tag release
git tag -a vX.Y.Z -m "<release summary>"

# Push to origin
git push origin main
git push origin vX.Y.Z

# Verify
git status -sb
git show -1 --stat
git ls-remote --tags origin | grep "vX.Y.Z"
```

---

## STOP CONDITIONS

**Immediately stop and report if:**

1. Any `bash -n` syntax check fails
2. Version strings don't match between scripts
3. Dry-run mode makes actual system changes
4. Test outputs show FAIL counts > 0
5. Cannot run a required command (report what's missing)

**Do NOT:**
- Invent command outputs
- Skip test validation
- Auto-fix errors without showing cause
- Break backward compatibility without deprecation period

---

## Best Practices

1. **Idempotency First** - Every script must be safe to re-run
2. **Evidence Trail** - Logs, reports, and artifacts for every operation
3. **Safe Defaults** - Dry-run by default, explicit apply flags only
4. **Read-Only Health** - Checker never modifies state, only reports
5. **Minimal Diffs** - Small, focused changes with clear rationale

---

## E16 Gen2 / Ubuntu LTS Specific Notes

**Hardware Context:**
- ThinkPad E16 Gen2 (AMD Ryzen 7)
- Ubuntu 24.04 LTS (primary), 22.04 LTS (fallback)

**Key Considerations:**
1. **Firmware** - fwupd recommended but not forced; show available updates first
2. **Power** - Detect laptop, suggest TLP as alternative to power-profiles-daemon
3. **AMD Microcode** - Auto-detect CPU vendor, install appropriate package
4. **SMART Health** - Recommend smartmontools but don't auto-install
5. **Journal Health** - Filter priority ≤3, dedupe messages, show top 10

---

## Version History Reference

- **v4.0.2** (current) - Centralized versioning, explicit dry-run banners, read-only checker
- **v4.0.1** - Initial --version support, Makefile safety improvements
- **v4.0.0** - Modular v4 rewrite with profiles (minimal/dev/secure)

---

## Quick Reference Commands

```bash
# Current state check
cd ~/ubuntu-bootstrap && git status -sb && git describe --tags

# Version check
bash scripts/bootstrap.sh --version && bash scripts/checks/bootstrap_check.sh --version

# Syntax validation
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# Safe dry-run test
bash scripts/bootstrap.sh --profile minimal --dry-run

# Health check (read-only)
bash scripts/checks/bootstrap_check.sh
```
