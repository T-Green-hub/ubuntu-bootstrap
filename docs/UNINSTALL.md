# Uninstall Guide

Complete guide for uninstalling components installed by ubuntu-bootstrap.

## Table of Contents

- [Quick Start](#quick-start)
- [Safety Features](#safety-features)
- [Per-Module Uninstall](#per-module-uninstall)
- [Batch Uninstall](#batch-uninstall)
- [DRY RUN Mode](#dry-run-mode)
- [FORCE Mode](#force-mode)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Quick Start

### Test Before Running (Recommended)

```bash
# Preview what would be removed (safe - makes no changes)
DRY_RUN=1 FORCE=1 bash scripts/dev-modules/python.sh
```

### Uninstall Single Module

```bash
# Interactive uninstall with confirmations
cd /path/to/ubuntu-bootstrap
source scripts/dev-modules/python.sh
uninstall_python
```

### Uninstall All Modules

```bash
# Coming soon - central orchestrator
./scripts/uninstall_bootstrap.sh --all
```

## Safety Features

All uninstall functions include multiple safety layers:

### 1. Detection Check
- Only runs if module is actually installed
- Prevents errors from running on clean systems

### 2. User Confirmation
- Interactive prompt before making changes
- Shows what will be removed
- Can be skipped with `FORCE=1` (use carefully!)

### 3. Automatic Backups
- Creates timestamped backup directory
- Saves configuration files
- Stores shell RC file backups
- Location: `~/.config/bootstrap-backups/<module>-YYYYMMDD-HHMMSS/`

### 4. DRY RUN Mode
- Preview all changes without making them
- Perfect for testing and planning
- Set: `DRY_RUN=1`

### 5. Logging
- All operations logged with timestamps
- Easy to track what happened
- Useful for troubleshooting

## Per-Module Uninstall

### Utilities Module

**What it removes:**
- bat (modern cat replacement)
- eza (modern ls replacement)
- fd-find (modern find replacement)
- ripgrep (fast text search)
- tldr (simplified man pages)

**Command:**
```bash
source scripts/dev-modules/utilities.sh
uninstall_utilities
```

**Backup includes:**
- None (utilities don't create config files)

**Notes:**
- Safe to run - no data loss risk
- Removes packages installed via APT

---

### VS Code Module

**What it removes:**
- Visual Studio Code application
- Microsoft APT repository
- GPG key for VS Code repository

**Command:**
```bash
source scripts/dev-modules/vscode.sh
uninstall_vscode
```

**Backup includes:**
- List of installed extensions
- Settings and keybindings (from ~/.config/Code)

**Notes:**
- Your workspace settings are preserved in project directories
- Extensions list saved for easy reinstallation
- User data directory (`~/.config/Code`) preserved by default

---

### Node.js Module

**What it removes:**
- nvm (Node Version Manager)
- All installed Node.js versions
- Global npm packages
- NVM configuration from shell RC files

**Command:**
```bash
source scripts/dev-modules/nodejs.sh
uninstall_nodejs
```

**Backup includes:**
- `nvm list` output (installed versions)
- Shell RC files (.bashrc, .profile, .zshrc)

**Notes:**
- Removes `~/.nvm` directory
- Cleans NVM_DIR and nvm init lines from shell configs
- Project-specific `node_modules` are NOT removed

---

### Python Module

**What it removes:**
- pyenv (Python Version Manager)
- All installed Python versions
- pyenv configuration from shell RC files

**Command:**
```bash
source scripts/dev-modules/python.sh
uninstall_python
```

**Backup includes:**
- `pyenv versions` output
- Shell RC files (.bashrc, .profile, .zshrc)

**Notes:**
- Removes `~/.pyenv` directory
- Cleans PYENV_ROOT and pyenv init lines from shell configs
- Virtual environments in project directories are NOT removed
- You may need to recreate venvs if you reinstall Python

---

### Rust Module

**What it removes:**
- rustup (Rust toolchain manager)
- All Rust toolchains
- cargo and installed crates
- ~/.cargo and ~/.rustup directories
- Rust configuration from shell RC files

**Command:**
```bash
source scripts/dev-modules/rust.sh
uninstall_rust
```

**Backup includes:**
- rustup settings (settings.toml)
- cargo config (config.toml)
- Shell RC files (.bashrc, .profile, .zshrc)

**Notes:**
- Uses `rustup self-uninstall` if available
- Falls back to manual cleanup if rustup command unavailable
- Cleans cargo env sourcing from shell configs
- Rust projects in other directories are NOT affected

---

### Go Module

**What it removes:**
- Go installation (/usr/local/go)
- Go configuration from shell RC files
- Optionally: ~/go workspace (asks user)

**Command:**
```bash
source scripts/dev-modules/go.sh
uninstall_go
```

**Backup includes:**
- Go workspace file list (~/go contents)
- Shell RC files (.bashrc, .profile, .zshrc)

**Notes:**
- **Requires sudo** to remove /usr/local/go
- **Preserves ~/go by default** (contains your projects!)
- Separate confirmation required to remove ~/go workspace
- Cleans GOPATH and Go PATH from shell configs
- Your Go projects are safe unless you explicitly delete ~/go

---

### Docker Module

**What it removes:**
- Docker Engine and all components
- All Docker containers (running and stopped)
- All Docker images
- All Docker volumes
- All Docker networks
- Docker configuration files
- User removed from docker group
- Docker APT repository and GPG key
- Optionally: /var/lib/docker (asks user)

**Command:**
```bash
source scripts/dev-modules/docker.sh
uninstall_docker
```

**Backup includes:**
- Docker images list
- Docker containers list
- daemon.json configuration

**⚠️  CRITICAL WARNINGS:**
- **DATA LOSS RISK**: This removes ALL Docker data
- **Two confirmations required**:
  1. Type "yes" to confirm Docker removal
  2. Type "DELETE" to confirm /var/lib/docker removal
- **Data directory size** is displayed before deletion
- **Stops all services** before removal
- **Preserves /var/lib/docker by default** for safety

**Safety recommendations:**
1. **Export important images first:**
   ```bash
   docker save my-image:latest | gzip > my-image-backup.tar.gz
   ```

2. **Backup volumes:**
   ```bash
   docker run --rm -v my-volume:/data -v $(pwd):/backup ubuntu \
     tar czf /backup/my-volume-backup.tar.gz /data
   ```

3. **Run in DRY_RUN mode first:**
   ```bash
   DRY_RUN=1 FORCE=1 source scripts/dev-modules/docker.sh
   uninstall_docker
   ```

**Notes:**
- Services are stopped before uninstallation
- Requires sudo for package removal
- **Must log out and back in** after uninstall (group membership change)
- Most destructive uninstall - use carefully!

---

## Batch Uninstall

### Central Orchestrator (Coming Soon)

```bash
# Interactive mode - choose modules
./scripts/uninstall_bootstrap.sh

# Uninstall all modules
./scripts/uninstall_bootstrap.sh --all

# Uninstall specific modules
./scripts/uninstall_bootstrap.sh --modules nodejs,python,rust

# Preview mode (DRY RUN)
./scripts/uninstall_bootstrap.sh --all --dry-run
```

### Makefile Targets (Coming Soon)

```bash
# Interactive uninstall
make uninstall

# Uninstall all (with confirmation)
make uninstall-all

# Dry run preview
make uninstall-dry

# Uninstall specific module
make uninstall-module MODULE=nodejs
```

## DRY RUN Mode

Preview changes without making them.

### How to Use

Set the `DRY_RUN` environment variable before calling uninstall:

```bash
DRY_RUN=1 source scripts/dev-modules/python.sh
uninstall_python
```

### What DRY RUN Does

- ✅ Shows all operations that would be performed
- ✅ Creates backup directory structure (no files copied)
- ✅ Validates detection logic
- ✅ Tests all code paths
- ❌ Does NOT modify files
- ❌ Does NOT remove directories
- ❌ Does NOT uninstall packages
- ❌ Does NOT modify shell configurations

### Example Output

```
[2025-11-04T15:30:45+00:00] Starting Python uninstall...
[2025-11-04T15:30:45+00:00] [DRY RUN] Would create backup directory: /home/user/.config/bootstrap-backups/python-20251104-153045
[2025-11-04T15:30:45+00:00] Created backup directory: /home/user/.config/bootstrap-backups/python-20251104-153045
[2025-11-04T15:30:45+00:00] Backup location: /home/user/.config/bootstrap-backups/python-20251104-153045
[2025-11-04T15:30:45+00:00] [DRY RUN] Would backup pyenv version info
[2025-11-04T15:30:45+00:00] [DRY RUN] Would backup .bashrc
[2025-11-04T15:30:45+00:00] [DRY RUN] Would remove: ~/.pyenv
[2025-11-04T15:30:45+00:00] [DRY RUN] Would remove 'export PYENV_ROOT=...' from .bashrc
[2025-11-04T15:30:45+00:00] [DRY RUN] Python uninstall simulation complete
```

### When to Use DRY RUN

- ✅ Before first uninstall (see what happens)
- ✅ Testing on production systems
- ✅ Generating documentation
- ✅ Debugging uninstall scripts
- ✅ Planning maintenance windows

## FORCE Mode

Skip all confirmations (use with caution!)

### How to Use

```bash
FORCE=1 source scripts/dev-modules/docker.sh
uninstall_docker
```

### What FORCE Does

- ✅ Skips user confirmation prompts
- ✅ Proceeds with all deletions automatically
- ✅ Useful for automation/scripts
- ⚠️  **DANGEROUS**: No chance to cancel

### When to Use FORCE

- ✅ Automated scripts/CI pipelines
- ✅ You're absolutely sure what you're doing
- ✅ Combined with DRY_RUN for testing

### When NOT to Use FORCE

- ❌ First time running uninstall
- ❌ Production systems with data
- ❌ When unsure about side effects
- ❌ On shared systems

### Combining DRY_RUN and FORCE

Safe way to test automation:

```bash
# Preview automation without making changes
DRY_RUN=1 FORCE=1 source scripts/dev-modules/python.sh
uninstall_python
```

## Backup and Recovery

### Backup Location

All backups are stored in:
```
~/.config/bootstrap-backups/<module>-YYYYMMDD-HHMMSS/
```

### What's Backed Up

| Module | Backup Contents |
|--------|-----------------|
| Utilities | *(none - no configuration)* |
| VS Code | Extension list, settings.json, keybindings.json |
| Node.js | nvm version list, shell RC files |
| Python | pyenv versions list, shell RC files |
| Rust | rustup/cargo configs, shell RC files |
| Go | Workspace file list, shell RC files |
| Docker | Image list, container list, daemon.json |

### Restoring from Backup

#### Shell Configuration Files

```bash
# Find your backup
ls -lt ~/.config/bootstrap-backups/

# Restore a shell RC file
cp ~/.config/bootstrap-backups/python-20251104-153045/.bashrc ~/.bashrc

# Restart shell
source ~/.bashrc
```

#### VS Code Extensions

```bash
# View backed up extensions
cat ~/.config/bootstrap-backups/vscode-20251104-153045/extensions.txt

# Reinstall extensions (manual)
code --install-extension <extension-id>
```

#### Docker Images

```bash
# View image list
cat ~/.config/bootstrap-backups/docker-20251104-153045/docker-images.txt

# Manually pull needed images
docker pull <image-name>
```

### Manual Backup Before Uninstall

For extra safety, create your own backup:

```bash
# Backup entire home config
tar czf ~/config-backup-$(date +%Y%m%d).tar.gz \
  ~/.bashrc ~/.profile ~/.zshrc \
  ~/.config/Code \
  ~/.nvm ~/.pyenv ~/.cargo ~/.rustup ~/go

# List contents without extracting
tar tzf ~/config-backup-20251104.tar.gz | head
```

## Troubleshooting

### Common Issues

#### "Module not installed" but I know it is

**Problem:** Detection logic might not match your installation method.

**Solution:**
```bash
# Check manually
command -v node  # For Node.js
command -v python  # For Python
command -v rustc  # For Rust
which go  # For Go
docker --version  # For Docker

# If installed differently, adapt the uninstall function
# or remove manually
```

#### Uninstall stuck at sudo password

**Problem:** Script needs sudo but you're not in sudoers.

**Solution:**
```bash
# Run the whole script with sudo (not recommended)
sudo bash scripts/dev-modules/go.sh

# Or add yourself to sudoers (better)
su -c "usermod -aG sudo $USER"
# Log out and back in
```

#### Shell config not cleaned properly

**Problem:** Module still loads after uninstall.

**Solution:**
```bash
# Check what's left
grep -n "PYENV\|NVM_DIR\|cargo" ~/.bashrc

# Manual cleanup
nano ~/.bashrc
# Remove offending lines
source ~/.bashrc
```

#### "Permission denied" errors

**Problem:** Don't have write access to files/directories.

**Solution:**
```bash
# Check ownership
ls -la ~/.pyenv

# Fix ownership if needed
sudo chown -R $USER:$USER ~/.pyenv

# Then retry uninstall
```

#### Docker uninstall fails

**Problem:** Containers still running or permissions issues.

**Solution:**
```bash
# Stop all containers first
docker stop $(docker ps -aq)

# Try uninstall again
source scripts/dev-modules/docker.sh
uninstall_docker

# If still fails, manual cleanup:
sudo systemctl stop docker.service docker.socket
sudo apt-get remove --purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker  # WARNING: Data loss!
```

### Getting Help

1. **Check logs:** Uninstall functions log all operations
2. **Run in DRY_RUN:** See what would happen: `DRY_RUN=1 ...`
3. **Check backups:** Review what was backed up
4. **Manual removal:** Sometimes manual is safer
5. **Open an issue:** Include OS version, module, error messages

## FAQ

### Q: Will uninstalling break my system?

**A:** No. These uninstall functions only remove what the bootstrap installed. System packages are not touched.

### Q: Can I undo an uninstall?

**A:** Partially. Shell configs can be restored from backups. Applications need to be reinstalled using the install functions.

### Q: What happens to my projects?

**A:** Your projects are **NOT touched**. Only the tools (Node.js, Python, etc.) are removed. Your code, node_modules, venvs, etc. remain.

### Q: Do I need to uninstall before upgrading?

**A:** No. Just run the install function again. It will detect existing installations and upgrade if needed.

### Q: What if I used a different installation method?

**A:** These uninstall functions are designed for bootstrap-installed components. If you installed Node.js via APT instead of nvm, you'll need to uninstall differently.

### Q: Can I uninstall just one Node.js version?

**A:** Not with these scripts. They remove nvm entirely. For managing individual versions, use nvm directly:
```bash
nvm uninstall 20.0.0
```

### Q: Will Docker uninstall delete my volumes?

**A:** Only if you confirm removal of `/var/lib/docker`. By default, it's preserved. You'll be asked specifically.

### Q: How much disk space will I recover?

**A:** Varies by module:
- Utilities: ~50MB
- VS Code: ~300MB
- Node.js: ~500MB per version installed
- Python: ~400MB per version
- Rust: ~2GB
- Go: ~500MB + your workspace
- Docker: ~2GB + images/containers/volumes (can be many GB)

### Q: Can I schedule automatic uninstalls?

**A:** Yes, using FORCE mode and cron:
```bash
# Crontab example (careful!)
0 2 * * 0 DRY_RUN=1 FORCE=1 /path/to/uninstall_bootstrap.sh --all
```

### Q: What's the safest way to test?

**A:** Always use DRY_RUN mode first:
```bash
DRY_RUN=1 FORCE=1 source scripts/dev-modules/python.sh
uninstall_python
```

### Q: Can I contribute uninstall functions for other modules?

**A:** Yes! See `CONTRIBUTING.md` for guidelines. Follow the pattern from existing modules.

---

## Next Steps

- Read [POST_INSTALL.md](POST_INSTALL.md) for recommended configurations
- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Check [README.md](../README.md) for general project info

---

*Last updated: 2025-11-04*
*Version: 2.0.0-beta*
