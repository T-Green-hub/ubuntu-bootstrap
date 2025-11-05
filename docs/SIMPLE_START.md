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

The installer just:
- ✅ Installed essential packages (curl, git, vim, etc.)
- ✅ Optimized your laptop battery
- ✅ Set up security (firewall)
- ✅ Installed developer tools (Docker, Node.js, Python, etc.)

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

## Next Steps

1. **Log out and log back in** (to use Docker without sudo)

2. **Pick your tools:**
   - Want coding? → Already done! ✅
   - Want privacy? → `scripts/60_optional-features.sh protonvpn brave`
   - Want office? → `scripts/60_optional-features.sh libreoffice`

3. **Customize your setup:**
   - Battery saver: Already optimized! ✅
   - Dark mode: Settings → Appearance
   - More apps: Ubuntu Software Center

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
