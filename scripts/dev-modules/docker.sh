#!/usr/bin/env bash
# Module: Docker installation and management
# Installs Docker Engine, CLI, Compose, and optional service templates

set -euo pipefail

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source library functions (if available, otherwise try to locate them)
if [[ -f "$LIB_DIR/logging.sh" ]]; then
    source "$LIB_DIR/logging.sh"
    source "$LIB_DIR/privileged.sh"
    source "$LIB_DIR/package.sh"
else
    # Fallback for when running in a different context
    echo "Library files not found in $LIB_DIR"
    exit 1
fi

# Default configuration
DRY_RUN="${DRY_RUN:-0}"
AUTO_YES="${AUTO_YES:-0}"
INTERACTIVE="${INTERACTIVE:-0}"

# Install Docker Engine
install_docker() {
    log_step "Installing Docker Engine..."

    # Check if already installed
    if command -v docker >/dev/null 2>&1; then
        log_info "Docker is already installed: $(docker --version)"
        return 0
    fi

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would install Docker Engine, CLI, and Compose"
        log_info "[DRY RUN] Would add user $USER to docker group"
        return 0
    fi

    # Install prerequisites
    apt_install ca-certificates curl gnupg

    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    run_privileged install -m 0755 -d /etc/apt/keyrings

    # Download key safely
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            run_privileged gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        run_privileged chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    # Set up the repository
    log_info "Setting up Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        run_privileged tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and install
    apt_update
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Verify installation
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker installation failed (command not found)"
        return 1
    fi

    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        log_info "Adding user $USER to 'docker' group..."
        run_privileged usermod -aG docker "$USER"
        log_warning "You must log out and back in for 'docker' group membership to take effect."
    fi

    log_success "Docker installed successfully"
}

# Create Docker Compose templates
install_templates() {
    local template_dir="$HOME/docker-templates"

    log_step "Creating Docker Compose templates..."
    log_info "Target directory: $template_dir"

    if (( DRY_RUN == 1 )); then
        log_info "[DRY RUN] Would create templates for: Nginx, Redis, MySQL"
        return 0
    fi

    mkdir -p "$template_dir"

    # Nginx Template
    cat > "$template_dir/nginx-compose.yml" <<EOF
version: '3.8'
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: always
EOF
    log_success "Created Nginx template: $template_dir/nginx-compose.yml"

    # Redis Template
    cat > "$template_dir/redis-compose.yml" <<EOF
version: '3.8'
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: always
volumes:
  redis_data:
EOF
    log_success "Created Redis template: $template_dir/redis-compose.yml"

    # MySQL Template
    cat > "$template_dir/mysql-compose.yml" <<EOF
version: '3.8'
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: example_root_password
      MYSQL_DATABASE: my_database
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    restart: always
volumes:
  db_data:
EOF
    log_success "Created MySQL template: $template_dir/mysql-compose.yml"

    log_info "Templates ready in $template_dir"
    log_info "Usage: docker compose -f $template_dir/nginx-compose.yml up -d"
}

# Main execution
main() {
    local install_templates_flag=0

    # Parse args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --templates)
                install_templates_flag=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--templates] [--dry-run]"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done

    install_docker

    if (( install_templates_flag == 1 )); then
        install_templates
    elif (( INTERACTIVE == 1 )); then
        # Only prompt if not running in a script that might have set INTERACTIVE=0 explicitly
        echo ""
        log_info "Docker module loaded."
        if [[ -t 0 ]]; then # Only run if stdin is a terminal
             read -p "Create Docker Compose templates (Nginx, Redis, MySQL)? [y/N] " -n 1 -r
             echo
             if [[ $REPLY =~ ^[Yy]$ ]]; then
                 install_templates
             fi
        fi
    fi
}

# Run main if sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
