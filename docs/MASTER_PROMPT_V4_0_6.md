# COPILOT AGENT PROMPT — ubuntu-bootstrap v4.0.6
## "CI-Proof + Interactive Automation + Truth Pass"

---

### Context
- **Current state:** v4.0.5 tagged; self-test now runs without hanging (fixed in v4.0.5)
- **Blocker found:** bootstrap.sh still calls `sudo` even with `--dry-run`, breaks CI
- **Goal:** Make toolkit CI-proof, add non-interactive chooser, update evidence docs
- **Scope:** 2–3 hours of focused work; no breaking changes

---

### Hard Rules (Non-Negotiable)
1. **Dry-run = truly no-op**: No sudo calls, no actual system changes, no password prompts
2. **CI must not hang**: All commands complete within 120s total; no interactive input
3. **All claims must be evidence-backed**: If docs say "PASS", test output must show it
4. **Idempotent**: Running bootstrap 2x should result in same safe end state
5. **Read-only checks safe**: bootstrap_check.sh must not require sudo or modify system

---

### PHASE 1: RECON (Baseline Verification)

**Run these commands; paste FULL output into final summary:**

```bash
cd /home/tg/ubuntu-bootstrap

# 1. Confirm we're at v4.0.5
git describe --tags --always
git log --oneline -3

# 2. Verify syntax (must be ZERO errors)
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# 3. Check version outputs
bash scripts/bootstrap.sh --version
bash scripts/checks/bootstrap_check.sh --version

# 4. Attempt dry-run (may fail due to sudo prompts, that's expected)
timeout 30 bash scripts/bootstrap.sh --profile minimal --dry-run --yes \
    --output-dir /tmp/audit_dryrun 2>&1 | head -80 | tail -40

# 5. Check health (should complete without sudo)
timeout 30 bash scripts/checks/bootstrap_check.sh --output-dir /tmp/audit_check 2>&1 \
    | tail -30

# 6. Self-test current state (expected to fail on dry-run/profiles due to sudo)
timeout 120 bash scripts/tests/self_test.sh 2>&1 | grep -E "PASS|FAIL|===" | head -80
```

---

### PHASE 2: PLAN (Changes Required)

**Detailed change log; cite exact line numbers and reason:**

#### A. Fix bootstrap.sh: Wrap Sudo Calls with DRY_RUN Check

| File | Lines | Change | Reason |
|------|-------|--------|--------|
| `scripts/bootstrap.sh` | 271, 335, 342, 409, ... | Wrap `sudo` commands: `if (( DRY_RUN == 0 )); then sudo ...; fi` | Dry-run should not prompt for password; CI-safe |

**Example:**
```bash
# BEFORE:
if (( DRY_RUN == 1 )); then
    echo "[DRY-RUN] Would check firmware..."
fi
sudo fwupdmgr refresh --force 2>/dev/null || true

# AFTER:
if (( DRY_RUN == 1 )); then
    echo "[DRY-RUN] Would check firmware..."
else
    sudo fwupdmgr refresh --force 2>/dev/null || true
fi
```

#### B. Add --choose Flag to bootstrap.sh

| File | Section | Change | Reason |
|------|---------|--------|--------|
| `scripts/bootstrap.sh` | Flags (~line 35–65) | Add `--choose <profile>` handler | Allow non-interactive profile selection |
| `scripts/bootstrap.sh` | Main flow (~line 300+) | Use `$CHOSEN_PROFILE` if set; skip interactive menu | Enables automation w/o user input |
| `scripts/bootstrap.sh` | Help (~line 120–130) | Document `--choose minimal\|dev\|secure` | User-facing documentation |

**Example:**
```bash
CHOSEN_PROFILE=""

case "$1" in
    --choose)
        if [[ "${2:-}" =~ ^(minimal|dev|secure)$ ]]; then
            CHOSEN_PROFILE="$2"
            shift 2
        else
            log_error "Invalid profile: $2. Use minimal, dev, or secure."
            exit 1
        fi
        ;;
esac

# Later in main flow:
if [[ -n "$CHOSEN_PROFILE" ]]; then
    PROFILE="$CHOSEN_PROFILE"
    # Skip interactive menu
else
    # Show interactive menu (existing code)
fi
```

#### C. Add --ci Flag to self_test.sh

| File | Section | Change | Reason |
|------|---------|--------|--------|
| `scripts/tests/self_test.sh` | Flags (add ~line 10–15) | Parse `--ci` flag; set `CI_MODE=1` | Enable CI-safe test mode |
| `scripts/tests/self_test.sh` | test_dry_run_profiles() | If `CI_MODE=1`, add `2>&1 >/dev/null` to stderr suppression | Suppress sudo prompts in CI |
| `scripts/tests/self_test.sh` | Timeouts | Use per-step: help=10s, version=10s, profiles=120s | Fine-grained timeout control |

**Example:**
```bash
CI_MODE=0

for arg in "$@"; do
    case "$arg" in
        --ci) CI_MODE=1 ;;
    esac
done

# In test functions:
if (( CI_MODE == 1 )); then
    # Run with stdin closed to prevent password prompt
    if run_with_timeout $TIMEOUT bash ... </dev/null 2>&1 | grep -q "error"; then
        test_fail "..."
    else
        test_pass "..."
    fi
fi
```

#### D. Update GitHub Actions CI Workflow

| File | Section | Change | Reason |
|------|---------|--------|--------|
| `.github/workflows/ci.yml` | (add new job or step) | Run `bash scripts/tests/self_test.sh --ci` | Automated gate; prevent regressions |

**Example job step:**
```yaml
- name: Run Self-Tests (CI Mode)
  run: |
    bash scripts/tests/self_test.sh --ci
  continue-on-error: false  # Fail if tests fail
```

#### E. Update Documentation

| File | Change | Reason |
|------|--------|--------|
| `docs/FINAL_TEST_OUTPUT_v4_0_4.md` | Add banner: "⚠️ INCOMPLETE — self-test hung on v4.0.4 (fixed in v4.0.5)" | Accurate historical record |
| `docs/FINAL_TEST_OUTPUT_v4_0_6.md` | Create new; paste outputs from: syntax check, help, version, health check, self-test --ci | Evidence-driven release notes |
| `docs/QUICK_START.md` (if exists) or `README.md` | Add section: "Non-interactive usage: `--choose minimal --dry-run --yes`" | User guidance |

---

### PHASE 3: PATCH (Implementation)

**You MUST show diffs for EVERY change. Implement in this exact order:**

1. **bootstrap.sh: Wrap sudo calls** (5–10 edits; ~50 lines changed)
   - Find all `sudo` commands
   - Wrap with `if (( DRY_RUN == 0 )); then ... fi`
   - Verify: `bash -n scripts/bootstrap.sh`

2. **bootstrap.sh: Add --choose flag** (3 edits; ~30 lines added)
   - Add flag parsing (~10 lines)
   - Add help text (~5 lines)
   - Conditionally skip interactive menu (~15 lines)
   - Verify: `bash -n scripts/bootstrap.sh`

3. **self_test.sh: Add --ci flag** (2 edits; ~20 lines added)
   - Add flag parsing (~5 lines)
   - Add CI-mode logic to test functions (~15 lines)
   - Verify: `bash -n scripts/tests/self_test.sh`

4. **.github/workflows/ci.yml: Add test step** (1 edit; ~5 lines added)
   - Insert new step after "Run syntax check" or similar
   - Verify: YAML is valid

5. **Docs: Update v4.0.4 and create v4.0.6 evidence**
   - Edit v4.0.4 file (1 line banner)
   - Create v4.0.6 file with test outputs (copy/paste from Phase 4)

6. **Update version.sh to 4.0.6** (1 edit; 1 line changed)

---

### PHASE 4: TEST (Verify Completeness)

**Run these in sequence; show FULL output for each:**

```bash
cd /home/tg/ubuntu-bootstrap

# 1. Syntax check on all modified files
echo "=== SYNTAX CHECK ==="
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/tests/self_test.sh
echo "✓ Syntax OK"

# 2. Dry-run with --choose (should NOT prompt for password)
echo ""
echo "=== DRY-RUN WITH --choose ==="
timeout 60 bash scripts/bootstrap.sh --choose minimal --dry-run --yes \
    --output-dir /tmp/v406_dryrun 2>&1 | head -100 | tail -50

# 3. Check artifacts exist
echo ""
echo "=== ARTIFACTS CHECK ==="
ls -la /tmp/v406_dryrun/ 2>/dev/null | head -20 || echo "No artifacts (expected if solo dry-run)"

# 4. Self-test in CI mode (must NOT hang, must complete <120s)
echo ""
echo "=== SELF-TEST --ci MODE ==="
time timeout 120 bash scripts/tests/self_test.sh --ci 2>&1 | tail -100

# 5. Health check (no sudo)
echo ""
echo "=== HEALTH CHECK ==="
timeout 30 bash scripts/checks/bootstrap_check.sh --output-dir /tmp/v406_check 2>&1 | tail -20

# 6. Verify CI workflow YAML syntax
echo ""
echo "=== CI WORKFLOW SYNTAX ==="
if command -v yamllint >/dev/null 2>&1; then
    yamllint .github/workflows/ci.yml || echo "yamllint not available (OK to skip)"
else
    python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "✓ YAML valid" || echo "✗ YAML invalid"
fi

# 7. Git diff summary
echo ""
echo "=== GIT DIFF SUMMARY ==="
git diff --stat
```

---

### PHASE 5: SHIP (Release)

```bash
cd /home/tg/ubuntu-bootstrap

# 1. Add all changes
git add -A

# 2. Review what you're committing
git status

# 3. Commit (use single commit with multiple changes for v4.0.6)
git commit -m "v4.0.6: CI-proof bootstrap, non-interactive chooser, truth pass on docs

- Wrap all sudo calls with DRY_RUN check; --dry-run no longer prompts
- Add --choose flag for non-interactive profile selection
- Add --ci flag to self_test.sh; integrates into GitHub Actions
- Update .github/workflows/ci.yml to run self-test
- Mark v4.0.4 evidence as incomplete; create v4.0.6 with full outputs
- All tests pass in CI mode; no hangs; <120s total"

# 4. Create annotated tag
git tag -a v4.0.6 -m "v4.0.6: CI-proof + chooser + docs truth pass"

# 5. Push to origin
git push origin main
git push origin v4.0.6

# 6. Final verification
echo "=== FINAL STATE ==="
git describe --tags --always
git log --oneline -1
```

---

### OUTPUT CONTRACT (Must Match)

Upon completion, paste into final message:

```
# v4.0.6 Release Summary

## Files Changed (git diff --stat)
[PASTE HERE]

## Critical Tests
- Syntax: [PASS/FAIL]
- Dry-run without sudo: [PASS/FAIL]
- Self-test --ci mode: [PASS/FAIL + time taken]
- Health check: [PASS/FAIL]

## Evidence Links
- v4.0.4 Updated: [LINK or "N/A"]
- v4.0.6 Evidence Created: [LINK]

## How to Use (3 commands)
1. [Dry-run example]
2. [Apply example (optional)]
3. [Verify example]

## Known Skips/Limitations
[List any expected failures or workarounds for user]

## Git Tag
v4.0.6 ✓ pushed to origin
```

---

### Bailout Conditions (Stop & Report)

If you encounter ANY of these, stop immediately and report findings:

- [ ] Syntax error in any modified file
- [ ] `--dry-run` still prompts for sudo password
- [ ] Self-test --ci hangs past 120s
- [ ] Bootstrap --choose rejects valid profile
- [ ] CI workflow YAML invalid
- [ ] Evidence docs not updated
- [ ] Version still showing 4.0.5 after changes

---

### Questions for Clarity (If Stuck)

1. **Sudo wrapping:** Should DRY_RUN also suppress stderr from sudo commands, or is "if (( DRY_RUN == 0 ))" sufficient?
2. **--ci tests:** Should tests skip entirely if CI_MODE=1, or just suppress output?
3. **CI gates:** Do all self-tests need to PASS, or can some be WARN and still pass?
4. **Profile validation:** Should --choose validate that profile is supported, or rely on bootstrap.sh validation?

---

### Success Criteria (You're Done When)

- [ ] `git tag -l v4.0.6` shows the tag exists
- [ ] `git push origin v4.0.6` succeeds
- [ ] `bash scripts/bootstrap.sh --choose minimal --dry-run --yes` completes in <30s, no password prompt
- [ ] `bash scripts/tests/self_test.sh --ci` completes in <120s, no password prompt
- [ ] `docs/FINAL_TEST_OUTPUT_v4_0_6.md` created with actual test outputs
- [ ] `docs/FINAL_TEST_OUTPUT_v4_0_4.md` updated with warning banner
- [ ] GitHub Actions CI workflow includes `bash scripts/tests/self_test.sh --ci`

---

### Time Budget
- Recon: 5 min
- Plan review: 5 min
- Implement Phase 3: 60–90 min
- Test Phase 4: 15–20 min
- Ship Phase 5: 5 min
- **Total: ~120 min (2 hours)**

---

### Attached Context
- Current repo: `ubuntu-bootstrap` (v4.0.5 tagged)
- Audit findings: `docs/V4_0_5_AUDIT_FINDINGS.md` (created in this session)
- Key blockers fixed: v4.0.4 self-test hang (v4.0.5), bootstrap_check.sh syntax error (v4.0.5)
- Current blocker: bootstrap.sh sudo calls in dry-run mode (blocking CI integration)

