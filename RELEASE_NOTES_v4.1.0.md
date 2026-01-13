# Release Notes v4.1.0

## 🌟 Master Prompt Alignment & Feature Expansion

This release brings the project into full alignment with the "Agent Mode Master Prompt" (2025), adding comprehensive support for virtualization, remote access, containerization templates, and user feedback.

### 🚀 New Features

#### 1. Docker Module Overhaul (Phase 2B)
- **Standalone Mode**: Can now be run independently (`scripts/dev-modules/docker.sh`).
- **Templates**: New `--templates` flag creates `docker-compose.yml` templates for:
  - Nginx (Web Server)
  - Redis (Cache)
  - MySQL (Database)

#### 2. Virtual Machine Management (Phase 2C)
- **New Script**: `scripts/optional-features/virtualization.sh`
- **VirtualBox**: One-click install of VirtualBox + Extension Pack.
- **QEMU/KVM**: Enterprise-grade virtualization setup (libvirt, virt-manager).
- **Interactive Menu**: Choose your hypervisor easily.

#### 3. Remote Tools Suite (Phase 2D)
- **New Script**: `scripts/optional-features/remote_tools.sh`
- **OpenSSH**: Server installation with UFW rule integration.
- **Remmina**: Remote Desktop Client with RDP/VNC plugins.

#### 4. Feedback System (Phase 2E)
- **New Script**: `scripts/optional-features/feedback.sh`
- **Telemetry**: Local CSV logging of user satisfaction (`bootstrap-logs/feedback.csv`).
- **Interactive**: Simple 1-5 rating system.

### 📋 Master Prompt Compliance
The project now supports all 9 Core Features requested in the Master Prompt:
1. ✅ Security Hardening
2. ✅ VPN Setup
3. ✅ DNS Privacy
4. ✅ Shell Customization
5. ✅ Development Profiles
6. ✅ Virtual Machine Setup (NEW)
7. ✅ Docker Setup (ENHANCED)
8. ✅ Remote Tools Setup (NEW)
9. ✅ User Feedback (NEW)

### 🛠️ Usage Updates
See `docs/MASTER_PROMPT_USAGE_GUIDE.md` for the complete user manual.
