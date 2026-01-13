# Phase 2 Quick Reference Guide

**For:** Ubuntu Bootstrap v4.0.7+
**Audience:** All Users (Beginners to Advanced)
**Last Updated:** 2026-01-13

---

## 🚀 What's New in Phase 2?

Phase 2 adds **user-friendly enhancements** that make ubuntu-bootstrap easier to understand and use:

1. **🔐 Security Hardening** - Clear explanations of what each tool does
2. **🌐 Privacy & VPN** - Simple DNS and ProtonVPN setup
3. **🎨 Shell Customization** - Choose your terminal experience
4. **🔧 Dev Profiles** - Pre-configured tool bundles for different workflows

---

## 🎯 Quick Start

### For Complete Beginners
```bash
# 1. See what will happen (no changes made)
bash scripts/bootstrap.sh --profile minimal --dry-run

# 2. Run it for real
bash scripts/bootstrap.sh --profile minimal --yes

# 3. Check everything is working
bash scripts/checks/bootstrap_check.sh
```

### For Developers
```bash
# 1. Install dev tools (Node.js + Python + Docker)
bash scripts/bootstrap.sh --profile dev --yes

# 2. Configure your shell
bash scripts/lib/customization.sh --interactive

# 3. Set up DNS privacy
bash scripts/lib/dns_privacy.sh --interactive
```

### For Security-Minded Users
```bash
# 1. Install security hardening
bash scripts/bootstrap.sh --profile secure --yes

# 2. Set up VPN privacy
bash scripts/optional-features/protonvpn.sh

# 3. Configure encrypted DNS
bash scripts/lib/dns_privacy.sh --provider cloudflare
```

---

## 🎓 Understanding Each Feature

### Feature 1: DNS Privacy (🌐 Private Internet)

**What it does:** Encrypts your DNS queries so your ISP can't see which websites you visit

**How to use:**
```bash
bash scripts/lib/dns_privacy.sh --interactive
```

**Options:**
- **Cloudflare** - Fastest, popular choice
- **Cloudflare + Malware** - Blocks malware domains too
- **Cloudflare + Family** - Blocks adult content
- **Google** - Highly reliable
- **Quad9** - Security-focused
- **Mullvad** - Privacy-focused
- **NextDNS** - Fully customizable

**How It Works:**
```
Normal DNS (UNSAFE):
┌─────────────┐
│  Your PC    │ → plaintext DNS query → ISP → Google → Block at ISP
└─────────────┘

DNS over TLS (SECURE):
┌─────────────┐
│  Your PC    │ → ENCRYPTED query → DNS Server → Response ENCRYPTED
└─────────────┘
ISP can't see websites you visit!
```

---

### Feature 2: Shell Customization (🎨 Terminal)

**What it does:** Lets you choose and customize your command-line shell

**Options:**
```
🐚 Bash (Default)
   - Universal, available everywhere
   - Best for: Learning, scripting, compatibility
   - Features: Basic, reliable, proven

⚡ Zsh (Enhanced)
   - Powerful with plugins and themes
   - Best for: Advanced users, development
   - Features: Oh-My-Zsh, autocompletion, themes

🐟 Fish (Modern)
   - Super beginner-friendly
   - Best for: New to command line
   - Features: Auto-suggestions, syntax highlighting
```

**How to use:**
```bash
# See what shell you're using
bash scripts/lib/customization.sh --status

# Install Zsh with themes
bash scripts/lib/customization.sh --install-zsh

# Configure Bash defaults
bash scripts/lib/customization.sh --configure-bash
```

---

### Feature 3: Dev Profiles (🔧 Development Tools)

**What it does:** Groups useful development tools into pre-configured bundles

**Available Profiles:**

```
🔧 minimal
   Best for: Learning, scripting
   Includes: gcc, git, curl, vim, build-essential
   Size: ~500 MB
   Use case: "I just want basics"

🌐 fullstack
   Best for: Web development (frontend + backend)
   Includes: Node.js, Python, Docker, Git, VS Code
   Size: ~3 GB
   Use case: "I build web apps"

🤖 ai-ml
   Best for: Machine learning, data science
   Includes: Python + TensorFlow, PyTorch, Jupyter
   Size: ~4 GB
   Use case: "I work with AI/ML models"

⚙️  systems
   Best for: Low-level programming
   Includes: Rust, Go, C/C++, LLVM, GDB
   Size: ~2.5 GB
   Use case: "I code in Rust/Go/C++"

🎯 custom
   Best for: Mix and match what you need
   Includes: You choose!
   Size: Varies
   Use case: "I want specific tools"
```

**How to use:**
```bash
# See available profiles
bash scripts/dev-modules/profiles.sh --list

# Install a profile
bash scripts/dev-modules/profiles.sh --profile fullstack

# Check what's installed
bash scripts/dev-modules/profiles.sh --status
```

---

### Feature 4: Security Hardening (🔐 Protection)

**New Protection Tools Explained:**

#### 🚫 Fail2Ban (Brute-Force Protection)
```
What it does: Blocks attackers trying many password attempts
How: Monitors failed login attempts, temporarily blocks attacker's IP
Why: Prevents "brute force" password cracking attacks
Log: /var/log/fail2ban.log
```

#### 📝 Auditd (System Auditing)
```
What it does: Records all system activity for compliance/forensics
How: Logs file access, user commands, permission changes
Why: Helps troubleshoot issues, meets compliance requirements
Log: /var/log/audit/audit.log
```

#### 🦠 ClamAV (Antivirus)
```
What it does: Scans files for known malware
How: Uses signature database, updates daily
Why: Protects against Windows malware on shared files
Usage: clamscan /path/to/file
```

---

## 🎬 Common Workflows

### Workflow 1: Complete Fresh Setup (30 minutes)
```bash
# 1. Update system
bash scripts/bootstrap.sh --profile dev --yes

# 2. Configure privacy
bash scripts/lib/dns_privacy.sh --interactive

# 3. Personalize shell
bash scripts/lib/customization.sh --interactive

# 4. Install VPN (optional)
bash scripts/optional-features/protonvpn.sh

# 5. Verify everything
bash scripts/checks/bootstrap_check.sh
```

**Result:** Fully configured, private, development-ready Ubuntu system

---

### Workflow 2: Just Privacy (5 minutes)
```bash
# Setup encrypted DNS
bash scripts/lib/dns_privacy.sh --provider cloudflare

# Optional: Install VPN app
bash scripts/optional-features/protonvpn.sh
```

**Result:** ISP can't see your browsing, encrypted DNS queries

---

### Workflow 3: Developer Environment (45 minutes)
```bash
# Install dev tools
bash scripts/dev-modules/profiles.sh --profile fullstack

# Configure development shell (Zsh)
bash scripts/lib/customization.sh --install-zsh

# Setup Git & SSH (from profiles module)
bash scripts/dev-modules/profiles.sh --setup-git

# Verify installation
node --version && python3 --version && docker --version
```

**Result:** Complete development environment ready to code

---

## ❓ Frequently Asked Questions

### Q: Do I need to use all Phase 2 features?
**A:** No! Each feature is optional. You can:
- Skip VPN if you don't need it
- Keep using Bash if it works for you
- Not install dev profiles if you're not developing
- Use only what you need

### Q: Is this secure for real?
**A:** Yes! All tools are industry-standard:
- UFW: Used by major Linux distros
- Fail2Ban: Used by web hosting providers
- ClamAV: Industry-standard antivirus
- DNS over TLS: Used by 1M+ people
- ProtonVPN: Trusted by journalists/activists

### Q: Can I undo changes?
**A:** Mostly yes! You can:
- Switch shells: `chsh -s /bin/bash`
- Disable VPN: Close ProtonVPN app
- Reset DNS: `sudo resolvectl revert <interface>`
- Remove tools: `sudo apt remove <package>`

### Q: How much disk space?
```
Minimal profile:    +200 MB
Dev profile:        +2.5 GB (includes Docker)
Security tools:     +300 MB
VPN + DNS setup:    +50 MB
```

### Q: Will this break my system?
**A:** No! Phase 2 is:
- Idempotent (safe to run multiple times)
- Non-destructive (no data deleted)
- Reversible (can undo most changes)
- Backward compatible (works with v4.0.6)

### Q: I'm not technical, is this for me?
**A:** YES! Each step includes "How It Works" explanations:
- Emoji icons show what each tool does
- Plain English explanations (no jargon)
- Visual diagrams for complex topics
- "Best for" recommendations

---

## 🛠️ Troubleshooting

### Problem: Emojis display as boxes
**Solution:**
```bash
# Install emoji font
sudo apt install fonts-noto-color-emoji

# Use modern terminal:
# - GNOME Terminal 3.45+
# - Kitty
# - Alacritty
```

### Problem: DNS not changing
**Solution:**
```bash
# Check current DNS
systemctl status systemd-resolved

# Apply changes
sudo systemctl restart systemd-resolved

# Verify
resolvectl status
```

### Problem: Shell switch didn't work
**Solution:**
```bash
# Make sure shell is available
cat /etc/shells | grep zsh

# Set it manually
chsh -s /bin/zsh

# Log out and back in
```

### Problem: ProtonVPN not connecting
**Solution:**
```bash
# Check if installed
which protonvpn-app

# Check logs
journalctl -xe | grep protonvpn

# Reinstall if needed
bash scripts/optional-features/protonvpn.sh --reinstall
```

### Problem: Command not found after installation
**Solution:**
```bash
# Reload shell environment
exec $SHELL

# Or restart terminal

# Check installation
bash scripts/dev-modules/profiles.sh --status
```

---

## 📖 Learn More

For detailed information, see:

| Topic | File |
|-------|------|
| Phase 2 Overview | `docs/PHASE_2_ENHANCEMENTS.md` |
| All Features | `docs/PHASE_2_IMPLEMENTATION_SUMMARY.md` |
| Validation Plan | `docs/PHASE_2_VALIDATION_PLAN.md` |
| Troubleshooting | `docs/TROUBLESHOOTING.md` |
| Full Documentation | `docs/README.md` |

---

## ⏱️ Performance Expectations

```
Dry-run (preview):           ~10 seconds
Minimal profile:             ~2-3 minutes
Dev profile:                 ~10-15 minutes (with Docker)
Security profile:            ~5-8 minutes
DNS setup:                   ~30 seconds
Shell customization:         ~2 minutes
Full workflow:               ~30-45 minutes
```

---

## 🎉 You're Ready!

Phase 2 makes ubuntu-bootstrap more user-friendly by:
✅ Explaining everything clearly
✅ Providing visual indicators
✅ Offering flexible options
✅ Respecting your choices
✅ Supporting all skill levels

**Get started now:**
```bash
bash scripts/bootstrap.sh --help
```

---

**Questions?** Check the docs/ folder or GitHub Issues
**Found a bug?** Report it with `--debug` output
**Have feedback?** Share it in GitHub Discussions

**Happy bootstrapping! 🚀**

