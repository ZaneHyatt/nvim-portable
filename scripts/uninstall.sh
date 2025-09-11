#!/usr/bin/env bash
set -euo pipefail
CONFIG_DIR="$HOME/.config/nvim"
read -p "Remove symlink $CONFIG_DIR (backups untouched)? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  if [ -L "$CONFIG_DIR" ]; then rm -f "$CONFIG_DIR"; fi
  echo "Done."
else
  echo "Aborted."
fi
