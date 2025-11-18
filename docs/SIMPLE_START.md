# 🚀 Ubuntu Bootstrap - Simple Start Guide

**Get Ubuntu 24.04 ready for development in 5 minutes!**

---

## What You'll Get

✅ Essential development tools  
✅ Better battery life on laptops  
✅ Privacy & security hardening  
✅ Everything tested and working  

---

## Step 1: Copy & Paste This

Open terminal (`Ctrl+Alt+T`) and run:

```bash
sudo apt update && sudo apt install -y git make
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
make run
```

**That's it!** ☕ Grab coffee while it installs (3-5 minutes).

---

## What Just Happened?

The installer just completed 8 automated steps:

1. ✅ **Configured APT** - Fast, reliable package downloads
2. ✅ **Installed essentials** - git, vim, curl, wget, htop, build tools
3. ✅ **Set up hardware** - Graphics drivers, WiFi firmware, Bluetooth
4. ✅ **Hardened security** - Firewall, DNS privacy, secure settings
5. ✅ **Added dev tools** - Docker, Node.js, Python, Rust, Go, VS Code
6. ✅ **Optimized laptop** - Battery life (20-80% charging), power management
7. ✅ **Installed optional apps** - (if you selected them)
8. ✅ **Verified everything** - Checked that all installations work

**Time taken:** Usually 5-15 minutes depending on your internet speed

**What's different now?**
- Your terminal has new commands: `docker`, `node`, `python`, `code`
- Battery lasts longer (smart charging thresholds)
- System is more secure (UFW firewall active)
- Everything is ready for development or daily use

---

## Quick Commands

```bash
# See what's installed
make verify

# Install privacy tools (ProtonVPN, Brave browser)
scripts/60_optional-features.sh protonvpn brave

# Preview before installing (safe mode)
DRY_RUN=1 make run
```

---

## What To Do Now (Post-Installation Steps)

### 1. Restart Required (Important!)

```bash
sudo reboot
```

**Why?** Some changes (like WiFi drivers and Docker) need a reboot to work properly.

### 2. After Reboot - Test Your New Tools

Open a terminal and try these commands:

```bash
# Check Docker works
docker --version
docker ps

# Check Node.js works
node --version
npm --version

# Check Python works
python --version

# Open VS Code
code
```

**All commands work?** ✅ Perfect! Everything is installed correctly.

### 3. Optional - Add More Software

Want privacy tools?

```bash
cd ubuntu-bootstrap
scripts/60_optional-features.sh protonvpn brave
```

Want office software?

```bash
scripts/60_optional-features.sh libreoffice
```

Want backups?

```bash
scripts/60_optional-features.sh timeshift
```

### 4. Customize Ubuntu

- **Dark mode:** Settings → Appearance → Style → Dark
- **Power settings:** Settings → Power (already optimized for battery!)
- **More apps:** Open "Ubuntu Software" app and browse
- **Keyboard shortcuts:** Settings → Keyboard → View and Customize Shortcuts

---

## Common Questions

**Q: Is this safe?**  
A: Yes! Preview first with `DRY_RUN=1 make run`

**Q: Can I undo this?**  
A: Yes! See [Uninstall Guide](UNINSTALL.md)

**Q: My laptop model isn't listed?**  
A: No problem! We use safe defaults that work everywhere.

**Q: Something broke?**  
A: Check [Troubleshooting Guide](TROUBLESHOOTING.md)

---

## 3 Most Useful Commands

```bash
# 1. Full installation
make run

# 2. Check system health
make verify

# 3. Install privacy tools
scripts/60_optional-features.sh protonvpn brave
```

---

## Need More Help?

📖 **Detailed Guide:** [Full Installation Guide](INSTALL.md)  
🔧 **Problems?** [Troubleshooting](TROUBLESHOOTING.md)  
📚 **All Docs:** [Documentation Index](INDEX.md)

---

**Made with ❤️ for Ubuntu users**
