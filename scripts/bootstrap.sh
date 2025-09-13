#!/usr/bin/env bash
set -euo pipefail


# Required: set REPO_SLUG like "ZaneHyatt/nvim-portable" in your one-liner
REPO_SLUG="${REPO_SLUG:-YOUR_GH_USERNAME/YOUR_REPO_NAME}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/nvim-portable/${REPO_SLUG//\//_}}"


if [[ "$REPO_SLUG" == *YOUR_GH_USERNAME* ]]; then
echo "[error] Set REPO_SLUG env var (e.g., REPO_SLUG=ZaneHyatt/nvim-portable)" >&2
exit 2
fi


TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT


echo "==> Fetching $REPO_SLUG@$BRANCH…"
curl -fsSL "https://github.com/$REPO_SLUG/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$TMP"
mkdir -p "$INSTALL_DIR"
# repo folder is like <name>-<branch>
REPO_NAME=$(basename "$REPO_SLUG")
mv "$TMP/$REPO_NAME-$BRANCH"/* "$INSTALL_DIR" 2>/dev/null || mv "$TMP"/* "$INSTALL_DIR"


# Guard: ensure we now have nvim/init.lua
if [[ ! -f "$INSTALL_DIR/nvim/init.lua" ]]; then
echo "[error] nvim/init.lua not found after download; check REPO_SLUG/BRANCH" >&2
exit 3
fi


cd "$INSTALL_DIR"
bash scripts/install.sh
