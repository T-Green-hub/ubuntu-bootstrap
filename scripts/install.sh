#!/usr/bin/env bash
# Ubuntu Bootstrap - CLI Installer
# Installs ubuntu-bootstrap command to ~/.local/bin

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    cat <<EOF
Ubuntu Bootstrap CLI Installer

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --uninstall    Remove installed CLI wrapper
    --help, -h     Show this help

DESCRIPTION:
    Installs 'ubuntu-bootstrap' command to ~/.local/bin for easy access.
    The command will be available system-wide if ~/.local/bin is in your PATH.

EXAMPLES:
    $0                  # Install
    $0 --uninstall      # Uninstall

EOF
}

install_cli() {
    echo ""
    echo "Installing ubuntu-bootstrap CLI..."
    echo ""

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Create wrapper script
    cat > "$INSTALL_DIR/ubuntu-bootstrap" <<'EOF'
#!/usr/bin/env bash
# Ubuntu Bootstrap CLI Wrapper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try to find bootstrap repo
if [[ -n "${UBUNTU_BOOTSTRAP_DIR:-}" ]]; then
    BOOTSTRAP_DIR="$UBUNTU_BOOTSTRAP_DIR"
elif [[ -f "$HOME/ubuntu-bootstrap/scripts/bootstrap.sh" ]]; then
    BOOTSTRAP_DIR="$HOME/ubuntu-bootstrap"
elif [[ -f "/opt/ubuntu-bootstrap/scripts/bootstrap.sh" ]]; then
    BOOTSTRAP_DIR="/opt/ubuntu-bootstrap"
else
    echo "Error: Cannot find ubuntu-bootstrap installation"
    echo "Set UBUNTU_BOOTSTRAP_DIR environment variable or install to ~/ubuntu-bootstrap"
    exit 1
fi

# Delegate to bootstrap.sh
exec bash "$BOOTSTRAP_DIR/scripts/bootstrap.sh" "$@"
EOF

    chmod +x "$INSTALL_DIR/ubuntu-bootstrap"

    echo -e "${GREEN}✓${NC} Installed: $INSTALL_DIR/ubuntu-bootstrap"
    echo ""

    # Check PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        echo -e "${GREEN}✓${NC} $INSTALL_DIR is in your PATH"
        echo ""
        echo "You can now run: ubuntu-bootstrap --help"
    else
        echo -e "${YELLOW}⚠${NC} $INSTALL_DIR is NOT in your PATH"
        echo ""
        echo "Add to your PATH by adding this line to ~/.bashrc or ~/.profile:"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "Then reload: source ~/.bashrc"
    fi
    echo ""
}

uninstall_cli() {
    echo ""
    echo "Uninstalling ubuntu-bootstrap CLI..."
    echo ""

    if [[ -f "$INSTALL_DIR/ubuntu-bootstrap" ]]; then
        rm -f "$INSTALL_DIR/ubuntu-bootstrap"
        echo -e "${GREEN}✓${NC} Removed: $INSTALL_DIR/ubuntu-bootstrap"
    else
        echo "ubuntu-bootstrap CLI not installed"
    fi
    echo ""
}

main() {
    case "${1:-}" in
        --uninstall)
            uninstall_cli
            ;;
        --help|-h)
            show_help
            ;;
        "")
            install_cli
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
