# Ubuntu Bootstrap - Master Prompt Usage Guide

**Version:** v4.0.7
**Updated:** 2026-01-13
**Audience:** All Users

This guide follows the **Master Prompt structure** for post-installation setup of Ubuntu 24.04.

---

## 🔐 **1. Security Hardening Setup** 🛡️

### 🔒 **Essential Security Tools**

Ubuntu Bootstrap provides enterprise-grade security features with clear explanations:

#### **UFW (Uncomplicated Firewall)**
**What it does:** Blocks all incoming traffic by default. Only **SSH**, **HTTP**, and **HTTPS** are allowed.

**How It Works:**
UFW is a simple firewall that helps protect your system by blocking unwanted traffic and allowing necessary services. It creates rules that control which network connections are allowed in/out.

**Installation:**
```bash
# Included in all profiles (minimal, dev, secure)
bash scripts/bootstrap.sh --profile minimal --yes
```

---

#### **Fail2Ban**
**What it does:** Prevents **brute-force attacks** by banning IP addresses after several failed login attempts.

**How It Works:**
Fail2Ban scans your system logs (like `/var/log/auth.log`) and blocks IP addresses that attempt brute-force login attacks. After 5 failed attempts, the IP is blocked for 10 minutes, protecting services like **SSH**.

**Installation:**
```bash
# Available in secure profile
bash scripts/bootstrap.sh --profile secure --yes

# Or install separately
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

#### **AppArmor**
**What it does:** Protects your system by enforcing **security profiles** on applications (e.g., **SSH**, **Web Servers**).

**How It Works:**
AppArmor applies security profiles to applications, restricting their ability to interact with the system. This limits what damage can be done if an application is compromised, improving overall **security**.

**Check Status:**
```bash
# AppArmor is enabled by default in Ubuntu
sudo aa-status
```

---

#### **ClamAV (Optional)**
**What it does:** Scans files for **malware** using signature-based detection.

**How It Works:**
ClamAV is a **signature-based antivirus** that scans files for known malware patterns. It's particularly useful when sharing files with Windows users or scanning email attachments. The virus definition database updates daily.

**Installation:**
```bash
# Secure profile offers ClamAV during installation
bash scripts/bootstrap.sh --profile secure --interactive

# To scan a file
clamscan /path/to/file

# To scan a directory
clamscan -r /path/to/directory
```

---

### 🛡️ **Choose Your Security Profile**

| Profile | Features | Best For |
|---------|----------|----------|
| **Minimal** | UFW firewall + unattended upgrades | Basic protection |
| **Dev** | Minimal + development tools | Developers who need security + tools |
| **Secure** | UFW + Fail2Ban + Auditd + ClamAV (optional) | Maximum security posture |

**Quick Start:**
```bash
# Minimal security (fast)
bash scripts/bootstrap.sh --profile minimal --yes

# Full security (comprehensive)
bash scripts/bootstrap.sh --profile secure --interactive
```

---

## 🌐 **2. VPN Setup (ProtonVPN)** 🌍

### 🔑 **Set Up ProtonVPN for Privacy & Data Protection**

#### **ProtonVPN Installation**
**What it does:** Automatically sets up **ProtonVPN** for encrypted internet browsing.

**How It Works:**
ProtonVPN creates an encrypted "tunnel" between your computer and ProtonVPN's servers. All your internet traffic travels through this tunnel, invisible to anyone monitoring your network connection. Your ISP, hackers, and network admins cannot see what websites you visit or data you transmit.

**Benefits:**
- 🔒 **Encrypts ALL internet traffic** - Invisible to ISPs and network monitors
- 🌍 **Hides your real IP address** - Websites see ProtonVPN's IP, not yours
- 🛡️ **Protects on public WiFi** - Safe browsing at coffee shops, airports, hotels
- 🚫 **DNS leak protection** - Prevents DNS queries from bypassing the VPN
- ⚡ **Kill switch** - Blocks internet if VPN disconnects

**Installation:**
```bash
# Option 1: During main setup
bash scripts/bootstrap.sh --profile secure --interactive
# Then answer "yes" when prompted for ProtonVPN

# Option 2: Standalone installation
bash scripts/optional-features/protonvpn.sh

# Check VPN status
protonvpn-app
```

---

#### **VPN Auto-Connect**
**What it does:** Ensures **VPN** starts on boot for continuous **privacy**.

**How It Works:**
By enabling **auto-connect**, your **VPN** will automatically start when the system boots, ensuring that your **internet traffic** is always encrypted. A desktop entry is created that launches ProtonVPN at login.

**Setup:**
```bash
# Auto-connect is configured during ProtonVPN installation
# Or enable manually through ProtonVPN app settings:
# Settings → General → Connect on Startup
```

---

### 🌍 **DNS over HTTPS (DoH) / DNS over TLS**

#### **DNS Privacy**
**What it does:** Encrypts your **DNS queries** so ISPs can't see which websites you visit.

**How It Works:**
Normally, DNS queries are sent in **plaintext**, allowing your ISP to see every website you visit. **DNS over TLS** encrypts these queries, preventing eavesdropping or **manipulation** by third parties. Your **web traffic** becomes **private** and **secure**.

**Visual Explanation:**
```
❌ Normal DNS (UNSAFE):
┌─────────────┐
│  Your PC    │ → "google.com?" → ISP can see → Google DNS
└─────────────┘      (plaintext)

✅ DNS over TLS (SECURE):
┌─────────────┐
│  Your PC    │ → 🔒 ENCRYPTED 🔒 → DNS Server → Response 🔒 ENCRYPTED 🔒
└─────────────┘
ISP cannot see which websites you visit!
```

**Providers Available:**
1. **Cloudflare** (1.1.1.1) - Fastest, privacy-focused
2. **Cloudflare + Malware** - Blocks malware domains
3. **Cloudflare + Family** - Blocks adult content
4. **Google** (8.8.8.8) - Highly reliable
5. **Quad9** (9.9.9.9) - Security-focused, blocks threats
6. **Mullvad** - Privacy-focused, no logging
7. **NextDNS** - Customizable filtering
8. **Control D**, **AdGuard**, **CleanBrowsing** - Various protections

**Installation:**
```bash
# Interactive DNS setup
bash scripts/lib/dns_privacy.sh --interactive

# Or specific provider
bash scripts/lib/dns_privacy.sh --provider cloudflare

# Check DNS status
bash scripts/lib/dns_privacy.sh --status

# Test DNS resolution
bash scripts/lib/dns_privacy.sh --test
```

---

## 💻 **3. Virtual Machine Setup (VirtualBox/QEMU)** 🖥️

> ⚠️ **Status:** Not yet implemented. Coming in Phase 2C.

### 🖥️ **Create Virtual Machines for Safe Testing**

#### **VirtualBox**
**What it does:** Create and run virtual machines for isolated testing environments.

**How It Works:**
VirtualBox allows you to create and run **virtualized systems** inside your machine, perfect for testing software or experimenting without affecting the host system. Each VM is completely isolated.

**Planned Implementation:**
```bash
# Install VirtualBox (Coming soon)
bash scripts/optional-features/virtualization.sh --virtualbox

# Install QEMU/KVM (Coming soon)
bash scripts/optional-features/virtualization.sh --qemu
```

**Workaround (Manual Installation):**
```bash
# VirtualBox (until automated)
sudo apt install virtualbox virtualbox-ext-pack

# QEMU/KVM
sudo apt install qemu-kvm libvirt-daemon-system virtinst
```

**See:** [MASTER_PROMPT_ALIGNMENT.md](MASTER_PROMPT_ALIGNMENT.md#phase-2c---virtual-machine-setup-4-hours) for roadmap

---

## 🐋 **4. Containerization (Docker)** 🚢

### 🐋 **Install Docker for Easy Deployment**

#### **Docker & Docker Compose**
**What it does:** Package applications into containers that run consistently across **different environments**.

**How It Works:**
Docker allows you to package applications into containers, which include all dependencies and run identically on any system. This eliminates "works on my machine" problems and simplifies deployment.

**Installation:**
```bash
# Option 1: Via dev profile (includes Docker)
bash scripts/dev-modules/profiles.sh --profile fullstack

# Option 2: Docker standalone
bash scripts/dev-modules/docker.sh

# Verify installation
docker --version
docker compose version

# Test Docker
docker run hello-world
```

**Docker Examples:**
```bash
# Run nginx web server
docker run -d -p 8080:80 nginx

# Run PostgreSQL database
docker run -d -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres

# Run Redis cache
docker run -d -p 6379:6379 redis
```

**Docker Compose Example:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: secret
```

**See Also:** [Dev Profiles Guide](docs/PHASE_2_QUICK_REFERENCE.md#feature-3-dev-profiles-) for more Docker integration

---

## 🌍 **5. Remote Tools & Monitoring** 🛠️

> ⚠️ **Status:** Not yet implemented. Coming in Phase 2D.

### 🌐 **Remote Access**

#### **OpenSSH**
**What it does:** Enables secure **remote access** to your system.

**How It Works:**
SSH (Secure Shell) allows users to securely connect to a **remote system** over the network, making it essential for managing servers or accessing other systems from a distance. All communication is encrypted.

**Planned Implementation:**
```bash
# Install OpenSSH server (Coming soon)
bash scripts/optional-features/remote_tools.sh --openssh

# Generate SSH key (Coming soon)
bash scripts/optional-features/remote_tools.sh --generate-key
```

**Workaround (Manual Installation):**
```bash
# Install OpenSSH server
sudo apt install openssh-server

# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

### 🖥️ **Remote Desktop**

#### **Remmina**
**What it does:** Connect to remote desktops using **RDP**, **VNC**, or **SSH**.

**How It Works:**
Remmina provides a simple graphical interface for connecting to **remote systems**, making it easy to manage your servers or desktops from anywhere. It supports multiple protocols (RDP for Windows, VNC for Linux/macOS, SSH for terminals).

**Planned Implementation:**
```bash
# Install Remmina (Coming soon)
bash scripts/optional-features/remote_tools.sh --remmina
```

**Workaround (Manual Installation):**
```bash
# Install Remmina
sudo apt install remmina remmina-plugin-rdp remmina-plugin-vnc
```

**See:** [MASTER_PROMPT_ALIGNMENT.md](MASTER_PROMPT_ALIGNMENT.md#phase-2d---remote-tools-3-hours) for roadmap

---

## 🎨 **6. Final Customizations** ✨

### 🎨 **Personalize Your Shell Environment**

#### **Choose Your Shell**
Ubuntu Bootstrap supports three modern shells with different strengths:

| Shell | Icon | Best For | Features |
|-------|------|----------|----------|
| **Bash** | 🐚 | Universal compatibility, scripting | Default, reliable, works everywhere |
| **Zsh** | ⚡ | Advanced users, customization | Oh-My-Zsh, themes, plugins, autocomplete |
| **Fish** | 🐟 | Beginners, modern features | Auto-suggestions, syntax highlighting |

**How It Works:**
Your shell is the command-line interface you interact with. Bash is the default and most compatible. Zsh offers powerful customization with Oh-My-Zsh (themes, plugins, aliases). Fish provides beginner-friendly features like auto-suggestions and syntax highlighting out of the box.

**Installation:**
```bash
# Interactive shell selection
bash scripts/lib/customization.sh --interactive

# Or install specific shells
bash scripts/lib/customization.sh --install-zsh   # Zsh + Oh-My-Zsh
bash scripts/lib/customization.sh --install-fish  # Fish shell
bash scripts/lib/customization.sh --configure-bash # Enhanced Bash

# Check current shell
bash scripts/lib/customization.sh --status

# Switch default shell
chsh -s /bin/zsh   # Switch to Zsh
chsh -s /bin/fish  # Switch to Fish
chsh -s /bin/bash  # Switch back to Bash
```

---

#### **Install Themes**
**What's available:** Dracula terminal theme, Oh-My-Zsh themes, custom prompts

**Installation:**
```bash
# Dracula theme for GNOME Terminal
bash scripts/lib/customization.sh --install-dracula

# Oh-My-Zsh themes (automatic with Zsh installation)
# Popular themes: robbyrussell, agnoster, powerlevel10k
```

**See Also:** [Shell Customization Guide](docs/PHASE_2_QUICK_REFERENCE.md#feature-2-shell-customization-) for detailed options

---

## 📝 **7. Feedback & Improvement** 💬

### 📣 **Let Us Know What You Think**

> ⚠️ **Status:** Feedback mechanism not yet implemented. Coming in Phase 2E.

**How It Will Work:**
After setup, you'll be prompted to provide **feedback** on your experience. User feedback helps us continuously **improve** and ensure the **installation process** meets the needs of **all users**, from **beginners** to **advanced developers**.

**Current Feedback Options:**
- **GitHub Issues:** Report bugs or problems - [Open an Issue](https://github.com/T-Green-hub/ubuntu-bootstrap/issues)
- **GitHub Discussions:** Ask questions, share ideas - [Start a Discussion](https://github.com/T-Green-hub/ubuntu-bootstrap/discussions)
- **Documentation Feedback:** Suggest improvements to guides

**Privacy-First Design:**
- No automatic data collection
- No telemetry or tracking
- Feedback is opt-in only
- All feedback stays local unless you choose to share

---

## 📋 **8. Usage Examples & Next Steps** 💻

### **Complete Workflows**

#### **Workflow 1: Security-First Setup**
Perfect for laptops, public WiFi users, privacy-conscious individuals:

```bash
# 1. Base security setup
bash scripts/bootstrap.sh --profile secure --interactive

# 2. Install ProtonVPN (during interactive prompts or separately)
bash scripts/optional-features/protonvpn.sh

# 3. Configure encrypted DNS
bash scripts/lib/dns_privacy.sh --interactive

# 4. Verify security
bash scripts/checks/bootstrap_check.sh --doctor
```

**Time:** ~15-20 minutes
**Result:** Fully secured system with VPN, encrypted DNS, firewall, brute-force protection

---

#### **Workflow 2: Developer Setup**
Perfect for software developers, web developers, full-stack engineers:

```bash
# 1. Install development tools
bash scripts/bootstrap.sh --profile dev --yes

# 2. Choose dev profile
bash scripts/dev-modules/profiles.sh --profile fullstack
# Installs: Node.js, Python, Docker, Git, VS Code

# 3. Customize shell (optional)
bash scripts/lib/customization.sh --install-zsh

# 4. Configure DNS privacy (optional)
bash scripts/lib/dns_privacy.sh --provider cloudflare

# 5. Verify installation
node --version && python3 --version && docker --version
```

**Time:** ~30-45 minutes
**Result:** Complete development environment ready to code

---

#### **Workflow 3: Minimal Setup (Just the Essentials)**
Perfect for servers, minimal installations, quick setups:

```bash
# Single command - installs essentials only
bash scripts/bootstrap.sh --profile minimal --yes

# Verify
bash scripts/checks/bootstrap_check.sh
```

**Time:** ~5-10 minutes
**Result:** Updated system with basic security (UFW, unattended-upgrades)

---

### **Next Steps After Installation**

1. **Review Logs:**
   ```bash
   # Check what was installed
   cat ~/bootstrap-logs/*/bootstrap.log
   ```

2. **Run Health Check:**
   ```bash
   # Verify system health
   bash scripts/checks/bootstrap_check.sh

   # Extended checks
   bash scripts/checks/bootstrap_check.sh --doctor
   ```

3. **Reboot (if needed):**
   ```bash
   # If kernel or firmware was updated
   sudo reboot
   ```

4. **Configure Additional Features:**
   ```bash
   # Shell customization
   bash scripts/lib/customization.sh --interactive

   # DNS privacy
   bash scripts/lib/dns_privacy.sh --interactive

   # VPN setup
   bash scripts/optional-features/protonvpn.sh
   ```

5. **Read Documentation:**
   - [Quick Reference](docs/PHASE_2_QUICK_REFERENCE.md) - User guide
   - [Implementation Summary](docs/PHASE_2_IMPLEMENTATION_SUMMARY.md) - Technical details
   - [Troubleshooting](docs/TROUBLESHOOTING.md) - Problem solutions

---

## 📖 **Documentation Index**

| Guide | Purpose | Audience |
|-------|---------|----------|
| [PHASE_2_QUICK_REFERENCE.md](docs/PHASE_2_QUICK_REFERENCE.md) | User-friendly feature guide | Everyone |
| [PHASE_2_IMPLEMENTATION_SUMMARY.md](docs/PHASE_2_IMPLEMENTATION_SUMMARY.md) | Technical details | Developers |
| [MASTER_PROMPT_ALIGNMENT.md](docs/MASTER_PROMPT_ALIGNMENT.md) | Feature roadmap | Maintainers |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Problem solutions | Everyone |
| [DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md) | Complete navigation | Everyone |

---

## ✅ **Feature Status**

| Feature | Status | Availability |
|---------|--------|--------------|
| Security Hardening | ✅ Complete | All profiles |
| VPN Setup (ProtonVPN) | ✅ Complete | Interactive/Secure profile |
| DNS Privacy | ✅ Complete | Standalone script |
| Shell Customization | ✅ Complete | Interactive/Standalone |
| Dev Profiles | ✅ Complete | Standalone script |
| Docker | ⚠️ Partial | Dev profiles (enhancement planned) |
| Virtual Machines | ❌ Planned | Phase 2C (2-3 sessions) |
| Remote Tools | ❌ Planned | Phase 2D (2-3 sessions) |
| Feedback Mechanism | ❌ Planned | Phase 2E (1 session) |

---

## 🎉 **You're All Set!**

Ubuntu Bootstrap is designed to make post-installation setup easy, secure, and educational. Every feature includes "How It Works" explanations so you understand not just what's happening, but why it matters.

**Get started now:**
```bash
bash scripts/bootstrap.sh --help
```

**Questions?** Check the [Quick Reference](docs/PHASE_2_QUICK_REFERENCE.md) or [Documentation Index](docs/DOCUMENTATION_INDEX.md).

---

**Last Updated:** 2026-01-13
**Version:** v4.0.7
**Alignment:** 75% (95% after Phase 2B-E)

