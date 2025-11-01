#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Validate and set repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Validate environment
if [[ ! -d "$REPO_DIR" ]]; then
  echo "[ERROR] Repository directory not found: $REPO_DIR"
  exit 1
fi

# Repository configuration
ORG="T-Green-hub"
NAME="ubuntu-bootstrap"

# Validate organization and name
if [[ ! "$ORG" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ ! "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "[ERROR] Invalid repository organization or name"
  exit 1
fi

REMOTE_SSH="git@github.com:${ORG}/${NAME}.git"

cd "$REPO_DIR" || {
  echo "[ERROR] Failed to change to repository directory"
  exit 1
}

# Ensure GitHub CLI exists
if ! command -v gh >/dev/null 2>&1; then
  echo "[!] 'gh' not found. Installing via apt…"
  type -p curl >/dev/null || { echo "[X] curl required"; exit 1; }
  curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 10 \
    https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod 0644 /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y gh
fi

# Init git if needed
if [ ! -d .git ]; then
  echo "[+] Initializing git repo on 'main'…"
  git init -b main
fi

# Configure git user if not already set
if ! git config --get user.name >/dev/null 2>&1; then
  echo "[+] Configuring git user.name…"
  # Try to detect from system first
  if command -v getent >/dev/null 2>&1; then
    REAL_NAME=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
    # Validate the name is not empty and is reasonable
    if [[ -n "$REAL_NAME" && "$REAL_NAME" != "$USER" && ${#REAL_NAME} -le 100 ]]; then
      git config user.name "$REAL_NAME"
      echo "[✓] Set git user.name to: $REAL_NAME"
    else
      git config user.name "$USER"
      echo "[✓] Set git user.name to: $USER"
    fi
  else
    git config user.name "$USER"
    echo "[✓] Set git user.name to: $USER"
  fi
else
  echo "[i] git user.name already set: $(git config --get user.name)"
fi

if ! git config --get user.email >/dev/null 2>&1; then
  echo "[+] Configuring git user.email…"
  # Use noreply GitHub email pattern for privacy
  EMAIL="${USER}@users.noreply.github.com"
  # Validate email format is reasonable
  if [[ "$EMAIL" =~ ^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+$ ]]; then
    git config user.email "$EMAIL"
    echo "[✓] Set git user.email to: $EMAIL"
  else
    echo "[ERROR] Generated invalid email format: $EMAIL"
    exit 1
  fi
else
  echo "[i] git user.email already set: $(git config --get user.email)"
fi

# Set safe pull strategy
if ! git config --get pull.rebase >/dev/null 2>&1; then
  git config pull.rebase false
  echo "[✓] Configured pull strategy (merge, not rebase)"
fi

# Ensure a useful .gitignore exists (idempotent)
if [ ! -f .gitignore ]; then
cat > .gitignore <<'EOF'
.vscode/
.idea/
__pycache__/
node_modules/
*.swp
*.swo
*~
.DS_Store
backups/
dist/
build/
*.log
logs/
EOF
fi

echo "[+] Staging + committing…"
git add -A
git commit -m "bootstrap: initial commit" || true

# Create or update remote, then push
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[+] Creating GitHub repo ${ORG}/${NAME} (private)…"
  gh auth status || gh auth login
  gh repo create "${ORG}/${NAME}" --private --source . --remote origin --push -y
else
  CURR_REMOTE="$(git remote get-url origin)"
  echo "[i] origin: ${CURR_REMOTE}"
  if [[ "${CURR_REMOTE}" != "${REMOTE_SSH}" ]]; then
    echo "[i] switching origin to ${REMOTE_SSH}"
    git remote set-url origin "${REMOTE_SSH}"
  fi
  echo "[+] Pushing main…"
  git push -u origin main
fi

echo "[✓] GitHub sync complete."
