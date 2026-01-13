# Release Process

This document describes how to create and verify releases for Ubuntu Bootstrap.

---

## Release Checklist

### 1. Pre-Release Verification

Before tagging a release, ensure all verification gates pass:

```bash
# Syntax validation (must be zero errors)
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# Self-test suite (must pass all tests)
bash scripts/tests/self_test.sh

# Dry-run test (must complete without errors)
bash scripts/bootstrap.sh --profile minimal --dry-run --yes

# Real-run test (CRITICAL - must complete without errors)
bash scripts/bootstrap.sh --profile minimal --yes --output-dir /tmp/release_test
```

### 2. Update Version

Update the version in `scripts/lib/version.sh`:

```bash
export BOOTSTRAP_VERSION="X.Y.Z"
```

### 3. Create Release Evidence

Generate verification bundles **before tagging**:

```bash
# Run bootstrap and capture output
bash scripts/bootstrap.sh --profile minimal --yes \
  --output-dir "$HOME/bootstrap-logs/ship_$(date +%Y%m%dT%H%M%SZ)"

# Run health check
bash scripts/checks/bootstrap_check.sh \
  --output-dir "$HOME/bootstrap-checks/ship_$(date +%Y%m%dT%H%M%SZ)"

# Create tarball of evidence
cd "$HOME"
tar -czf bootstrap_ship_TIMESTAMP.tar.gz \
  bootstrap-logs/ship_TIMESTAMP/ \
  bootstrap-checks/ship_TIMESTAMP/

# Generate SHA-256 checksum
sha256sum bootstrap_ship_TIMESTAMP.tar.gz > bootstrap_ship_TIMESTAMP.tar.gz.sha256

# Move to proof/bundles/ (not tracked in git)
mv bootstrap_ship_TIMESTAMP.tar.gz* /path/to/repo/proof/bundles/
```

### 4. Create Release Tag

```bash
# Create annotated tag
git tag -a vX.Y.Z -m "vX.Y.Z: Brief description of changes"

# Push tag to origin
git push origin vX.Y.Z
```

### 5. Create GitHub Release

Using the GitHub web UI:
1. Go to: https://github.com/T-Green-hub/ubuntu-bootstrap/releases/new
2. Select tag: `vX.Y.Z`
3. Release title: `Ubuntu Bootstrap vX.Y.Z`
4. Description: Paste content from `docs/RELEASE_NOTES_vX.Y.Z.md`
5. Attach assets:
   - Upload `bootstrap_ship_TIMESTAMP.tar.gz`
   - Upload `bootstrap_ship_TIMESTAMP.tar.gz.sha256`
6. Publish release

---

## Tagging Policy

- **Tags point to release commits:** Tags should reference the exact commit that was verified
- **Annotated tags only:** Use `git tag -a` to include metadata (author, date, message)
- **Semantic versioning:** Follow MAJOR.MINOR.PATCH convention
  - MAJOR: Breaking changes or major refactors
  - MINOR: New features, backward-compatible
  - PATCH: Bug fixes, documentation updates

---

## Release Assets

### What to Upload

Upload the following as GitHub Release assets:
- `bootstrap_ship_TIMESTAMP.tar.gz` - Complete evidence bundle (logs, reports, checksums)
- `bootstrap_ship_TIMESTAMP.tar.gz.sha256` - Checksum for integrity verification

### What NOT to Commit

**Do not add the following to git:**
- Large binary tarballs (> 1MB)
- Evidence bundles (proof/bundles/*.tar.gz)
- Temporary test artifacts

These files are intentionally excluded via `.gitignore` to keep repository size minimal.

---

## Verifying Release Assets

### Automated Verification

Use the provided verification script:

```bash
bash scripts/release/verify_release_assets.sh
```

Expected output:
```
✓ Base evidence bundle checksum verified
✓ Addendum evidence bundle checksum verified
✓ Final packet bundle checksum verified
✓ Base evidence results: PASS=11 WARN=1 FAIL=0
✓ Addendum evidence results: PASS=12 WARN=0 FAIL=0
All verifications passed.
```

### Manual Verification

Verify checksums manually:

```bash
# Verify base evidence
echo "EXPECTED_SHA256  proof/bundles/bootstrap_ship_TIMESTAMP.tar.gz" | sha256sum -c

# Extract and inspect
tar -xzf proof/bundles/bootstrap_ship_TIMESTAMP.tar.gz
cat bootstrap_ship_TIMESTAMP/report.json | python3 -m json.tool
```

---

## Post-Release Verification

After publishing a release, verify the following:

1. **Tag is visible on GitHub:** https://github.com/T-Green-hub/ubuntu-bootstrap/tags
2. **Release assets are downloadable:** Check release page
3. **Release notes are readable:** Markdown renders correctly
4. **Checksums match:** Download asset and verify SHA-256

---

## Rollback Procedure

If a release has critical issues:

1. **Do not delete the tag** - tags should be immutable
2. **Create a new patch release** (e.g., vX.Y.Z+1) with fixes
3. **Mark the problematic release as pre-release** on GitHub
4. **Update release notes** to indicate issues and point to fixed version

---

## v4.0.6 Release Example

For reference, here's how v4.0.6 was released:

```bash
# 1. Verify syntax
bash -n scripts/bootstrap.sh scripts/checks/bootstrap_check.sh scripts/lib/*.sh

# 2. Run full test suite
bash scripts/tests/self_test.sh

# 3. Generate evidence bundles
bash scripts/bootstrap.sh --profile minimal --yes --output-dir /tmp/ship_base
tar -czf proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz /tmp/ship_base/
sha256sum proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz > \
  proof/bundles/bootstrap_ship_20260113T091324Z.tar.gz.sha256

# 4. Create marker file
echo "v4.0.6 READY. SHA256: ..." > FINAL_PACKET_READY.txt
git add FINAL_PACKET_READY.txt
git commit -m "v4.0.6: Release marker"

# 5. Tag and push
git tag -a v4.0.6 -m "v4.0.6: APT_SAFE fix - production ready"
git push origin main
git push origin v4.0.6

# 6. Verify locally
bash scripts/release/verify_release_assets.sh

# 7. Create GitHub release with bundles as assets
```

---

## Support

For questions about the release process:
- Open an issue: https://github.com/T-Green-hub/ubuntu-bootstrap/issues
- Review existing releases: https://github.com/T-Green-hub/ubuntu-bootstrap/releases
