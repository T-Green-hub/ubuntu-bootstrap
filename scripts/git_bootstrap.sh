#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORG="T-Green-hub"
NAME="ubuntu-bootstrap"
REMOTE_SSH="git@github.com:${ORG}/${NAME}.git"

cd "$REPO_DIR"

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

# Safe git defaults only if unset (use existing or prompt for real values)
if ! git config --get user.name >/dev/null 2>&1; then
  # Try to detect from system first
  if command -v getent >/dev/null 2>&1; then
    REAL_NAME=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)
    if [[ -n "$REAL_NAME" && "$REAL_NAME" != "$USER" ]]; then
      git config user.name "$REAL_NAME"
    else
      git config user.name "$USER"
    fi
  else
    git config user.name "$USER"
  fi
fi

if ! git config --get user.email >/dev/null 2>&1; then
  # Generate a reasonable default email
  git config user.email "${USER}@$(hostname -f 2>/dev/null || echo 'localhost')"
fi
git config pull.rebase false

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
