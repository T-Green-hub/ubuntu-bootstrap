# Development Utilities - Quick Reference

## Package List

| Package | Command | Description |
|---------|---------|-------------|
| jq | `jq` | JSON processor and formatter |
| tree | `tree` | Directory structure visualizer |
| httpie | `http` | User-friendly HTTP client |
| ripgrep | `rg` | Faster grep alternative |
| fd-find | `fd` or `fdfind` | Faster find alternative |
| tmux | `tmux` | Terminal multiplexer |
| sqlite3 | `sqlite3` | SQLite database CLI |
| bat | `bat` or `batcat` | Enhanced cat with syntax highlighting |
| ncdu | `ncdu` | Disk usage analyzer with ncurses UI |

## Common Commands

### Installation

```bash
# Standard installation
source scripts/dev-modules/utilities.sh
install_dev_utilities

# From main bootstrap script
./scripts/run_bootstrap.sh
```

### Check Status

```bash
# Check if any utilities are installed
source scripts/dev-modules/utilities.sh
is_dev_utilities_installed && echo "Installed" || echo "Not installed"

# List installed utilities
get_installed_utilities

# Show versions
show_utility_versions
```

### Uninstallation

```bash
# Interactive uninstall
source scripts/dev-modules/utilities.sh
uninstall_dev_utilities

# Dry-run (safe testing)
DRY_RUN=1 uninstall_dev_utilities

# Force mode (no prompts)
FORCE=1 uninstall_dev_utilities

# Dry-run + Force
DRY_RUN=1 FORCE=1 uninstall_dev_utilities
```

## Utility Examples

### jq - JSON Processing

```bash
# Pretty print JSON
echo '{"name":"test","value":123}' | jq

# Extract field
echo '{"name":"test","value":123}' | jq '.name'

# Filter array
echo '[{"id":1},{"id":2}]' | jq '.[] | select(.id==1)'
```

### tree - Directory Visualization

```bash
# Show directory tree
tree

# Limit depth
tree -L 2

# Show hidden files
tree -a

# Only directories
tree -d
```

### httpie - HTTP Requests

```bash
# GET request
http GET https://api.github.com/users/octocat

# POST JSON
http POST httpbin.org/post name=test value=123

# Download file
http --download https://example.com/file.zip
```

### ripgrep - Fast Searching

```bash
# Search for pattern
rg "function"

# Search specific file types
rg "TODO" -t python

# Case insensitive
rg -i "error"

# Show context
rg -C 3 "pattern"
```

### fd - Fast File Finding

```bash
# Find files by name
fd "config"

# Find by extension
fd -e py

# Execute command on results
fd -e txt -x cat {}

# Hidden files
fd -H ".*rc$"
```

### tmux - Terminal Multiplexer

```bash
# Start new session
tmux

# List sessions
tmux ls

# Attach to session
tmux attach -t 0

# Split horizontally: Ctrl+b then "
# Split vertically: Ctrl+b then %
# Switch panes: Ctrl+b then arrow keys
```

### bat - Enhanced Cat

```bash
# View file with syntax highlighting
bat file.py

# Show line numbers
bat -n file.py

# Compare with plain output
bat --plain file.py

# Multiple files
bat file1.py file2.py
```

### ncdu - Disk Usage

```bash
# Analyze current directory
ncdu

# Analyze specific path
ncdu /var/log

# Scan without delete option
ncdu --read-only ~/

# Export to file
ncdu -o export.json
```

## Configuration Files

### Backed Up Automatically

When uninstalling, these files are backed up:

- `~/.tmux.conf` - tmux configuration
- `~/.ripgreprc` - ripgrep configuration  
- `~/.config/bat/` - bat themes and config
- `~/.sqlite_history` - sqlite command history
- `~/.config/httpie/` - httpie sessions and config

### Backup Location

```
~/.local/share/ubuntu-bootstrap/backups/dev-utilities-YYYYMMDD-HHMMSS/
```

## Symbolic Links

The module creates these symlinks for convenience:

- `~/.local/bin/fd` → `fdfind` (Ubuntu packages fd as fdfind)
- `~/.local/bin/bat` → `batcat` (Ubuntu packages bat as batcat)

**Note:** Add `~/.local/bin` to your PATH if not already included:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Troubleshooting

### Commands Not Found

If commands are not found after installation:

1. Check if packages are installed:
   ```bash
   dpkg -l | grep -E "jq|tree|httpie|ripgrep|fd-find|tmux|sqlite3|bat|ncdu"
   ```

2. Check symbolic links:
   ```bash
   ls -la ~/.local/bin/{fd,bat}
   ```

3. Verify PATH includes `~/.local/bin`:
   ```bash
   echo $PATH | grep -o "$HOME/.local/bin"
   ```

### Installation Fails

1. Update package lists:
   ```bash
   sudo apt-get update
   ```

2. Check for lock files:
   ```bash
   sudo fuser /var/lib/dpkg/lock-frontend
   ```

3. Fix broken packages:
   ```bash
   sudo apt-get install -f
   ```

### Uninstall Incomplete

If packages remain after uninstall:

```bash
# Manually remove remaining packages
sudo apt-get remove --purge jq tree httpie ripgrep fd-find tmux sqlite3 bat ncdu

# Clean up
sudo apt-get autoremove
```

## Environment Variables

### DRY_RUN

Run operations without making changes:

```bash
DRY_RUN=1 install_dev_utilities  # Simulate installation
DRY_RUN=1 uninstall_dev_utilities  # Simulate uninstall
```

### FORCE

Skip user confirmations:

```bash
FORCE=1 uninstall_dev_utilities  # No prompts
```

### Combined

```bash
DRY_RUN=1 FORCE=1 uninstall_dev_utilities  # Safe dry-run without prompts
```

## Integration with Bootstrap

The utilities module integrates with the main bootstrap script:

```bash
# From main script
./scripts/run_bootstrap.sh

# Select option: "4) Development Tools"
# Then select: "8) Additional Utilities"
```

## Version Information

Check installed versions:

```bash
source scripts/dev-modules/utilities.sh
show_utility_versions
```

Output example:

```
Installed utility versions:
  - jq: jq-1.6
  - tree: tree v1.8.0
  - httpie: 3.2.2
  - ripgrep: ripgrep 13.0.0
  - fd-find: fd 8.3.2
  - tmux: tmux 3.3a
  - sqlite3: 3.37.2
  - bat: bat 0.22.1
  - ncdu: ncdu 1.15.1
```

## Additional Resources

### Official Documentation

- jq: https://stedolan.github.io/jq/
- tree: https://linux.die.net/man/1/tree
- httpie: https://httpie.io/docs
- ripgrep: https://github.com/BurntSushi/ripgrep
- fd: https://github.com/sharkdp/fd
- tmux: https://github.com/tmux/tmux/wiki
- bat: https://github.com/sharkdp/bat
- ncdu: https://dev.yorhel.nl/ncdu

### Cheat Sheets

- tmux: https://tmuxcheatsheet.com/
- jq: https://stedolan.github.io/jq/manual/
- ripgrep: https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md

---

**Last Updated:** November 5, 2025  
**Module:** utilities.sh v2.0
