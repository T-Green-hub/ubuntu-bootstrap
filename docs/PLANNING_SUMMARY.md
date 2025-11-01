# Ubuntu Bootstrap — Strategic Planning Summary

**Created:** November 1, 2025  
**Status:** Planning Complete → Ready for Implementation

---

## 📄 Documentation Created

Three comprehensive planning documents have been created:

1. **`docs/ROADMAP.md`** (38KB)
   - Full strategic roadmap for Phases 2-4
   - Risk analysis and mitigation strategies
   - Success metrics and timeline
   - Community engagement strategy
   
2. **`docs/PHASE_2_1_UNINSTALL_GUIDE.md`** (27KB)
   - Step-by-step implementation guide for uninstall functionality
   - Complete code templates for all 7 dev-modules
   - Testing strategies and checklists
   - Ready-to-use scripts and patterns

3. **This file** - Quick reference summary

---

## 🎯 Immediate Next Steps (START HERE)

### Week 1-2: Implement Uninstall/Rollback

**Priority:** 🔴 CRITICAL  
**Why:** Blocks safe experimentation; most requested by users  
**Guide:** See `docs/PHASE_2_1_UNINSTALL_GUIDE.md`

**Quick Start:**
```bash
# 1. Create feature branch
git checkout -b feature/uninstall-implementation

# 2. Start with easiest module
# Edit scripts/dev-modules/utilities.sh
# Replace uninstall_dev_utilities() stub with real implementation

# 3. Test it
bash -c 'source scripts/dev-modules/utilities.sh && uninstall_dev_utilities'

# 4. Move to next module (order by complexity)
# utilities → vscode → nodejs → python → rust → go → docker
```

**Implementation Order:**
1. ✅ utilities.sh (Day 1-2) - Just apt packages
2. ✅ vscode.sh (Day 2-3) - Apt + repo cleanup
3. ✅ nodejs.sh (Day 4-6) - Directory + .bashrc
4. ✅ python.sh (Day 6-8) - Directory + .bashrc
5. ✅ rust.sh (Day 8-10) - rustup self-uninstall
6. ✅ go.sh (Day 10-12) - Directory + PATH
7. ✅ docker.sh (Day 12-14) - Most complex
8. ✅ Orchestrator (Day 15-16) - Central uninstall script

**Success Criteria:**
- [ ] All 7 modules have working uninstall functions
- [ ] Central orchestrator script created
- [ ] All modules create backups before removal
- [ ] DRY_RUN mode works for all modules
- [ ] Manual testing on VM passes
- [ ] No "not yet implemented" messages remain

---

## 📊 Phase Overview

### Phase 2: Foundation Hardening (Weeks 1-6)

**Goal:** Build the safety net for confident experimentation

| Task | Priority | Effort | Status |
|------|----------|--------|--------|
| 2.1 Uninstall/Rollback | 🔴 CRITICAL | 2-3 weeks | ⏳ NEXT |
| 2.2 Testing Infrastructure | 🔴 CRITICAL | 1 week | 📅 Week 3-4 |
| 2.3 Enhanced CI/CD | 🟡 MEDIUM | 3-4 days | 📅 Week 5 |

### Phase 3: User Empowerment (Weeks 7-12)

**Goal:** Give users control and recovery options

| Task | Priority | Effort | Status |
|------|----------|--------|--------|
| 3.1 Configuration Management | 🟡 MEDIUM | 3-4 days | 📅 Week 7-8 |
| 3.2 Backup & Restore | 🟠 HIGH | 2-3 days | 📅 Week 9-10 |
| 3.3 Web Dashboard | 🟢 LOW | 5-7 days | 📅 Optional |

### Phase 4: Expansion (Months 4-6)

**Goal:** Grow user base and enable community

| Task | Priority | Effort | Status |
|------|----------|--------|--------|
| 4.1 Multi-Distro Support | 🟠 HIGH | 7-10 days | 📅 Week 13-16 |
| 4.2 Plugin Architecture | 🟡 MEDIUM | 5-7 days | 📅 Week 17-20 |

---

## 🚨 Critical Gaps Addressed

### Current Problems (Before Implementation)

1. **Incomplete Rollback** ⚠️
   - Problem: Can't cleanly remove installed tools
   - Impact: Users afraid to try features
   - Solution: Phase 2.1 implements full uninstall

2. **Limited Testing** ⚠️
   - Problem: Only ProtonVPN has automated tests
   - Impact: Regressions slip through
   - Solution: Phase 2.2 creates test framework

3. **No Pre-Backup** ⚠️
   - Problem: Bootstrap modifies system without restore point
   - Impact: Fear of running on production machines
   - Solution: Phase 3.2 adds auto-snapshot

4. **Env Vars Only** ⚠️
   - Problem: 15+ config options hard to manage
   - Impact: Difficult to reproduce setups
   - Solution: Phase 3.1 adds config file support

---

## 📈 Success Metrics

### Phase 2 Complete When:
- ✅ All dev-modules have working uninstall
- ✅ Test coverage >75%
- ✅ CI tests on Ubuntu 22.04 + 24.04
- ✅ Zero "not yet implemented" messages

### Phase 3 Complete When:
- ✅ Config file controls all behavior
- ✅ Pre-bootstrap backup automated
- ✅ Restore guide tested and verified

### Phase 4 Complete When:
- ✅ Bootstrap works on 3+ distros
- ✅ 5+ community plugins available
- ✅ Plugin development guide published

---

## 🛠️ Quick Commands Reference

### Development Commands
```bash
# Create feature branch
git checkout -b feature/uninstall-implementation

# Test a single module
bash -c 'source scripts/dev-modules/utilities.sh && uninstall_dev_utilities'

# Test with dry-run
DRY_RUN=1 bash -c 'source scripts/dev-modules/docker.sh && uninstall_docker'

# Test orchestrator
bash scripts/uninstall_bootstrap.sh --help
DRY_RUN=1 bash scripts/uninstall_bootstrap.sh --all
```

### Testing Commands
```bash
# Run all tests (after Phase 2.2)
make test

# Run specific module test
bash scripts/dev-modules/test_nodejs_uninstall.sh

# Lint check
make lint-light
```

### Release Commands
```bash
# After Phase 2.1 complete
git tag v1.1.0 -m "Add uninstall/rollback for all dev-modules"
git push origin v1.1.0
make release TAG=v1.1.0
```

---

## 📚 Key Documents to Review

**Before Starting:**
1. Read `docs/ROADMAP.md` (Sections 1-2)
2. Read `docs/PHASE_2_1_UNINSTALL_GUIDE.md` (Full)
3. Review existing stubs in `scripts/dev-modules/*.sh`

**During Implementation:**
1. Follow templates in Phase 2.1 guide
2. Refer to `docs/DEPLOYMENT_CHECKLIST.md` for quality gates
3. Update `RELEASE_NOTES.md` as you go

**After Completion:**
1. Update `README.md` with uninstall section
2. Create `docs/UNINSTALL.md` with user guide
3. Update `docs/TROUBLESHOOTING.md` with uninstall issues

---

## 🤔 Key Decisions Made

### Design Decisions

1. **Uninstall Confirmation:** Use `FORCE=1` to skip (not `--force`)
   - Rationale: Consistent with DRY_RUN=1 pattern

2. **Backup Location:** `~/.local/share/ubuntu-bootstrap/backups/`
   - Rationale: XDG Base Directory spec compliance

3. **Uninstall Order:** Reverse of installation
   - Rationale: Handle dependencies gracefully

4. **Config Format:** YAML (not TOML or JSON)
   - Rationale: Most human-readable, supports comments

5. **Test Isolation:** System tests (not Docker)
   - Rationale: More realistic, faster for our use case

### Technical Decisions

1. **Package Manager Abstraction:** `pkg_install()`, `pkg_remove()`
   - Rationale: Enables multi-distro support in Phase 4

2. **Plugin API:** Hook-based (`pre_install`, `install`, `verify`, `uninstall`)
   - Rationale: Flexible, familiar pattern from WordPress/etc.

3. **Snapshot Tool:** TimeShift (not custom)
   - Rationale: Already supported, mature, GUI available

---

## ⚠️ Risk Mitigation

### Technical Risks

| Risk | Mitigation |
|------|------------|
| Uninstall removes wrong files | Double validation, dry-run, backups |
| Tests fail in CI | Containerized testing, matrix |
| Config bugs | Schema validation, extensive tests |

### Resource Risks

| Risk | Mitigation |
|------|------------|
| Maintainer burnout | Modular design, good docs, community |
| CI takes too long | Parallel jobs, caching, selective tests |

### User Risks

| Risk | Mitigation |
|------|------------|
| Breaking changes | Deprecation warnings, migration guides |
| Outdated docs | Documentation tests, reviews |

---

## 🎯 Definition of Done

### For Phase 2.1 (Uninstall)

- [ ] Code: All 7 modules have real uninstall functions
- [ ] Code: Central orchestrator script created
- [ ] Code: Backups created before any removal
- [ ] Code: Safety checks prevent dangerous operations
- [ ] Testing: Manual test on fresh VM passes
- [ ] Testing: Dry-run mode tested for all modules
- [ ] Testing: Full cycle (install → uninstall → verify)
- [ ] Docs: README.md updated with uninstall section
- [ ] Docs: UNINSTALL.md created with examples
- [ ] Docs: RELEASE_NOTES.md updated for v1.1.0
- [ ] Git: Feature branch merged to main
- [ ] Git: Tagged as v1.1.0
- [ ] Quality: No shellcheck warnings
- [ ] Quality: No "not yet implemented" messages

---

## 📞 Getting Help

### Documentation
- **Full roadmap:** `docs/ROADMAP.md`
- **Implementation guide:** `docs/PHASE_2_1_UNINSTALL_GUIDE.md`
- **Current checklist:** `docs/DEPLOYMENT_CHECKLIST.md`

### Code References
- **Existing test example:** `scripts/optional-features/test_protonvpn.sh`
- **Uninstall stub example:** `scripts/dev-modules/nodejs.sh` (line 48)
- **Current orchestrator:** `scripts/run_bootstrap.sh`

### Questions to Ask
1. "Does my uninstall function follow the standard template?"
2. "Have I added proper safety checks (path validation)?"
3. "Does dry-run mode work correctly?"
4. "Are configs backed up before removal?"
5. "Does verification detect successful removal?"

---

## 🚀 Launch Checklist

Before announcing Phase 2.1 completion:

- [ ] All code reviewed and tested
- [ ] Documentation complete and accurate
- [ ] CI passes on all tests
- [ ] Manual testing on clean system successful
- [ ] Release notes drafted
- [ ] Tag created: v1.1.0
- [ ] GitHub release published
- [ ] README badges updated
- [ ] Community announcement prepared

---

## 📅 Timeline Recap

```
Nov 4-5:    utilities + vscode uninstall
Nov 6-8:    nodejs + python uninstall
Nov 8-12:   rust + go + docker uninstall
Nov 13-14:  Central orchestrator + testing
Nov 15:     Documentation + release prep
Nov 18-22:  Phase 2.2 (Testing Infrastructure)
Nov 25-29:  Phase 2.3 (Enhanced CI/CD)
Dec 2-6:    Phase 3.1 (Config Management)
Dec 9-13:   Phase 3.2 (Backup & Restore)
```

**Critical Path:** Phase 2.1 → 2.2 → 3.2 (6 weeks minimum)

---

## ✅ Current Status

**✅ Planning:** COMPLETE  
**⏳ Implementation:** READY TO START  
**📅 Next Action:** Begin Phase 2.1 implementation (utilities.sh first)

---

**Last Updated:** November 1, 2025  
**Document Owner:** T-Green-hub  
**Review Date:** After Phase 2.1 completion
