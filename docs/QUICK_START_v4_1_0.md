# Quick Start Guide - v4.1.0

## 🚀 Get Started in 3 Steps

### 1️⃣ Clone and Navigate
```bash
git clone https://github.com/T-Green-hub/ubuntu-bootstrap.git
cd ubuntu-bootstrap
```

### 2️⃣ Choose Your Path
Pick the workflow that matches your needs:

#### 🔐 **Security-First Setup** (Recommended for Laptops)
Perfect for daily-driver systems prioritizing privacy and security.

```bash
# Dry-run to preview (safe, no changes)
bash scripts/bootstrap.sh --profile secure --dry-run

# Apply changes
sudo bash scripts/bootstrap.sh --profile secure --yes
```

**Includes**: UFW firewall, Fail2Ban, AppArmor, ClamAV, security-focused defaults.

#### 💻 **Developer Setup** (Best for Coding Workstations)
Full-stack development environment ready in minutes.

```bash
# Dry-run to preview
bash scripts/bootstrap.sh --profile dev --dry-run

# Apply changes
sudo bash scripts/bootstrap.sh --profile dev --yes
```

**Includes**: build-essential, Git, Python, Node.js, Docker, development utilities.

#### 🎯 **Minimal Setup** (Lightweight & Fast)
Essential tools only, perfect for servers or minimalist setups.

```bash
# Dry-run to preview
bash scripts/bootstrap.sh --profile minimal --dry-run

# Apply changes
sudo bash scripts/bootstrap.sh --profile minimal --yes
```

**Includes**: System updates, firmware, drivers, power management, basic security.

### 3️⃣ Add Optional Features
Enhance your setup with privacy tools, virtualization, or remote access:

```bash
# ProtonVPN for privacy
bash scripts/optional-features/protonvpn.sh

# Virtual machines (VirtualBox or QEMU/KVM)
bash scripts/optional-features/virtualization.sh --virtualbox

# Remote access (SSH server + Remmina client)
bash scripts/optional-features/remote_tools.sh --openssh --remmina

# Docker with ready-to-use templates
bash scripts/dev-modules/docker.sh --templates
```

---

## 📋 Common Workflows

### Workflow 1: Privacy-Focused Laptop
```bash
# Security + VPN + DNS Privacy
sudo bash scripts/bootstrap.sh --profile secure --yes
bash scripts/optional-features/protonvpn.sh
bash scripts/lib/dns_privacy.sh --interactive
```

### Workflow 2: Full-Stack Developer
```bash
# Dev tools + Docker + Custom shell
sudo bash scripts/bootstrap.sh --profile dev --yes
bash scripts/dev-modules/docker.sh --templates
bash scripts/lib/customization.sh --interactive  # Zsh + themes
```

### Workflow 3: Homelab Server
```bash
# Minimal + SSH + Docker
sudo bash scripts/bootstrap.sh --profile minimal --yes
bash scripts/optional-features/remote_tools.sh --openssh
bash scripts/dev-modules/docker.sh --templates
```

### Workflow 4: AI/ML Workstation
```bash
# AI profile + virtual machines for testing
bash scripts/dev-modules/profiles.sh --profile ai-ml
bash scripts/optional-features/virtualization.sh --qemu
```

---

## 🛠️ Advanced Usage

### Interactive Mode
Let the wizard guide you through options:
```bash
bash scripts/bootstrap.sh --interactive
```

### Dry-Run Mode (Preview Only)
See what would change without making any system modifications:
```bash
bash scripts/bootstrap.sh --profile <profile> --dry-run
```

### Health Check (Anytime)
Verify your system's security and configuration:
```bash
bash scripts/checks/bootstrap_check.sh
```

### Docker Templates
Generate `docker-compose.yml` files for common services:
```bash
bash scripts/dev-modules/docker.sh --templates
# Templates saved to: ~/docker-templates/
```

### Shell Customization
Choose your preferred shell (Bash, Zsh, Fish) with themes:
```bash
bash scripts/lib/customization.sh --interactive
```

---

## 📊 What Gets Installed?

### Minimal Profile
- System updates (apt upgrade)
- Firmware updates (fwupd)
- CPU microcode (AMD/Intel)
- Drivers (linux-firmware)
- Power management (power-profiles-daemon)
- Basic security (UFW firewall)

### Dev Profile (Minimal +)
- **Languages**: Python 3, Node.js, npm
- **Tools**: build-essential, git, curl, jq, vim
- **Utilities**: tmux, htop, tree
- **Docker**: Optional in fullstack profile

### Secure Profile (Minimal +)
- **Firewall**: UFW with default-deny rules
- **IDS**: Fail2Ban for SSH brute-force protection
- **Antivirus**: ClamAV scanner (optional)
- **Audit**: auditd for compliance logging

---

## 🔍 Verification

After installation, verify everything works:

```bash
# Check health
bash scripts/checks/bootstrap_check.sh

# Check versions
bash scripts/bootstrap.sh --version

# Check Docker
docker --version
docker compose version

# Check VPN (if installed)
protonvpn-app --version

# Check SSH (if installed)
systemctl status ssh
```

---

## 🆘 Troubleshooting

### Common Issues

**1. "Permission denied" errors**
- Solution: Prefix commands with `sudo` when making system changes.
- Dry-run mode never requires sudo: `bash scripts/bootstrap.sh --dry-run`

**2. "Package not found" errors**
- Solution: Ensure you're on Ubuntu 20.04+ LTS.
- Run: `sudo apt update && sudo apt upgrade -y`

**3. Docker group membership**
- After Docker install, log out and back in.
- Verify: `groups | grep docker`

**4. VPN won't connect**
- Ensure ProtonVPN credentials are configured.
- Check: `protonvpn-app` GUI or `protonvpn status`

**5. Firewall blocks SSH**
- If SSH is active, allow it: `sudo ufw allow OpenSSH`

---

## 📚 Next Steps

1. **Customize Your Setup**: Run `bash scripts/lib/customization.sh --interactive`
2. **Read the Master Guide**: See `docs/MASTER_PROMPT_USAGE_GUIDE.md`
3. **Check System Health**: `bash scripts/checks/bootstrap_check.sh --doctor`
4. **Provide Feedback**: `bash scripts/optional-features/feedback.sh --interactive`

---

## 🌟 Features at a Glance

| Feature | Script | Command |
|---------|--------|---------|
| Security Hardening | `bootstrap.sh` | `--profile secure` |
| VPN (ProtonVPN) | `protonvpn.sh` | Direct execution |
| DNS Privacy | `dns_privacy.sh` | `--interactive` |
| Shell Themes | `customization.sh` | `--interactive` |
| Docker + Templates | `docker.sh` | `--templates` |
| Virtual Machines | `virtualization.sh` | `--virtualbox` or `--qemu` |
| Remote Access | `remote_tools.sh` | `--openssh --remmina` |
| Dev Profiles | `profiles.sh` | `--profile <name>` |
| User Feedback | `feedback.sh` | `--interactive` |

---

## 💡 Pro Tips

- **Test First**: Always use `--dry-run` before applying changes.
- **Modular**: Install only what you need; scripts work independently.
- **Logs**: Check `/home/$USER/bootstrap-logs/<timestamp>/` for detailed logs.
- **Health Checks**: Run `bootstrap_check.sh` periodically to verify system state.
- **Idempotent**: Safe to re-run scripts; they check before installing.

---

**Version**: 4.1.0
**Last Updated**: January 13, 2026
**Compatibility**: Ubuntu 20.04 LTS, 22.04 LTS, 24.04 LTS
