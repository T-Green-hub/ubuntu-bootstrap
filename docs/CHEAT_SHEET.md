# 📋 Command Cheat Sheet

Quick reference for the most common commands.

---

## 🎯 Essential Commands (Use These Most)

### Install Everything
```bash
make run
```

### Preview Without Installing (Safe!)
```bash
DRY_RUN=1 make run
```

### Check System Health
```bash
make verify
```

---

## 🛠️ Developer Tools

### Install All Dev Tools
```bash
scripts/40_dev-tools.sh
```

### Install Specific Tools
```bash
# Pick what you need:
scripts/40_dev-tools.sh docker nodejs python rust go vscode utilities
```

### Individual Tool Install
```bash
scripts/40_dev-tools.sh docker       # Docker only
scripts/40_dev-tools.sh nodejs       # Node.js only
scripts/40_dev-tools.sh python       # Python only
```

---

## 🛡️ Privacy & Optional Tools

### Install ProtonVPN
```bash
scripts/60_optional-features.sh protonvpn
```

### Install Brave Browser
```bash
scripts/60_optional-features.sh brave
```

### Install Multiple Features
```bash
scripts/60_optional-features.sh protonvpn brave timeshift vlc libreoffice
```

### Privacy-First Setup
```bash
make privacy-first
```

---

## 🔍 System Detection

### Check Your Hardware
```bash
make detect
```

### Override Hardware Profile
```bash
HARDWARE_PROFILE=thinkpad-t14 make run    # ThinkPad
HARDWARE_PROFILE=hp-laptop-15 make run    # HP Laptop
HARDWARE_PROFILE=generic make run         # Any laptop
```

---

## 🧪 Testing & Dry Run

### Test Without Changes
```bash
DRY_RUN=1 make run
DRY_RUN=1 scripts/40_dev-tools.sh
DRY_RUN=1 scripts/60_optional-features.sh brave
```

### Run Tests
```bash
make test                              # All tests
make test-module MODULE=utilities      # Specific module
make test-syntax                       # Syntax check only
```

---

## 🗑️ Uninstall & Cleanup

### Uninstall Developer Tools
```bash
source scripts/dev-modules/docker.sh && uninstall_docker
source scripts/dev-modules/nodejs.sh && uninstall_nodejs
source scripts/dev-modules/python.sh && uninstall_python
source scripts/dev-modules/rust.sh && uninstall_rust
source scripts/dev-modules/utilities.sh && uninstall_dev_utilities
```

### Uninstall Optional Features
```bash
source scripts/optional-features/brave.sh && uninstall_brave
source scripts/optional-features/protonvpn.sh && uninstall_protonvpn
```

---

## 📦 Utilities (After Installation)

### Use New Tools
```bash
jq                    # JSON processor
rg "pattern"          # Fast text search (ripgrep)
fd "filename"         # Fast file finder
bat file.txt          # Better cat with syntax highlighting
ncdu                  # Disk usage analyzer
http GET url.com      # HTTP client (httpie)
```

### Launch Applications
```bash
brave-browser         # Brave browser
code                  # VS Code
protonvpn-app         # ProtonVPN
```

---

## 🔧 Advanced Options

### Skip Specific Scripts
```bash
scripts/run_bootstrap.sh --skip-script=40    # Skip dev tools
scripts/run_bootstrap.sh --skip-script=50    # Skip laptop optimization
```

### Custom Log Directory
```bash
LOG_DIR=/tmp/bootstrap-logs make run
```

### Strict Mode (Fail on Warnings)
```bash
STRICT=1 make run
```

---

## 🆘 Troubleshooting

### View Logs
```bash
ls -la logs/
cat logs/latest/*.log
```

### Check Installation Status
```bash
make verify
```

### Get Help
```bash
scripts/run_bootstrap.sh --help
```

---

## 📊 Information Commands

### System Information
```bash
make detect                    # Hardware detection
scripts/check_package_compat.sh --known    # Package compatibility
```

### Version Information
```bash
docker --version
node --version
python3 --version
rustc --version
go version
brave-browser --version
```

---

## 💡 Quick Tips

**Tip 1:** Always test with `DRY_RUN=1` first!
```bash
DRY_RUN=1 make run
```

**Tip 2:** Preview what a script does:
```bash
less scripts/40_dev-tools.sh
```

**Tip 3:** Copy commands easily - click code block!

**Tip 4:** Need help? All docs in `docs/` folder:
```bash
ls docs/
cat docs/INDEX.md
```

---

## 🔗 Quick Links

- **Full Guide:** [INSTALL.md](INSTALL.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Uninstall:** [UNINSTALL.md](UNINSTALL.md)
- **All Docs:** [INDEX.md](INDEX.md)

---

**Print this page for quick reference!**
