#!/usr/bin/env bash
set -euo pipefail

echo "Setting up mongo-sampler-dump for macOS..."
echo

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  echo "Homebrew is required for automatic macOS setup."
  echo "Install Homebrew from https://brew.sh, then run this script again."
  exit 1
}

ensure_tool() {
  local tool="$1"
  local formula="$2"
  local tap="${3:-}"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "Found $tool."
    return
  fi

  ensure_brew
  if [ -n "$tap" ]; then
    brew tap "$tap"
  fi

  echo "$tool not found. Installing $formula with Homebrew..."
  brew install "$formula"

  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: Installed $formula, but $tool is not available in PATH yet."
    echo "Open a new terminal, then run ./setup_mac.sh again."
    exit 1
  fi

  echo "Found $tool."
}

ensure_tool git git
ensure_tool node node
ensure_tool npm node
ensure_tool mongoimport mongodb-database-tools mongodb/brew

echo
echo "Installing project dependencies..."
npm install

if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    cp ".env.example" ".env"
    echo "Created .env from .env.example"
  else
    echo "WARNING: .env.example was not found. Create .env before running export/import."
  fi
else
  echo ".env already exists; leaving it unchanged."
fi

mkdir -p dump

echo
echo "Setup complete."
echo "Next steps:"
echo "  1. Edit .env with SOURCE_URI, DB_NAME, TARGET_URI, and TARGET_DB."
echo "  2. Run: npm run export"
echo "  3. Run: ./import_all.sh dump/YOUR_DB_FOLDER"
