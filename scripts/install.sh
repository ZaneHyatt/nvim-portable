#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Neovim portable config"
CONFIG_DIR="$HOME/.config/nvim"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SRC_DIR="$REPO_ROOT/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Add this guard near the top, after variables are set
if [ ! -f "$SRC_DIR/init.lua" ]; then
err "Couldn't find '$SRC_DIR/init.lua'. If you ran this via curl, use scripts/bootstrap.sh instead (see README)."; exit 2
fi

install_prereqs_linux() {
  if have apt; then
    sudo apt update
    sudo apt install -y neovim git curl ripgrep fd-find unzip build-essential python3 python3-pip nodejs npm
    if ! have fd && have fdfind; then sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true; fi
  elif have dnf; then
    sudo dnf install -y neovim git curl ripgrep fd-find unzip @development-tools python3 python3-pip nodejs npm
  elif have pacman; then
    sudo pacman -Syu --noconfirm neovim git curl ripgrep fd unzip base-devel python python-pip nodejs npm
  else
    err "Unsupported Linux distro. Install: neovim git curl ripgrep fd unzip build tools python3 nodejs npm"; exit 1
  fi
}

install_prereqs_macos() {
  if ! have brew; then
    msg "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$([ -f /opt/homebrew/bin/brew ] && echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' || echo 'eval \"$(/usr/local/bin/brew shellenv)\"')"
  fi
  brew update
  brew install neovim git ripgrep fd unzip node python
}

postinstall_headless() {
  msg "Bootstrapping plugins, LSPs, Treesitter (headless)…"
  nvim --headless \
    "+Lazy! sync" \
    "+MasonInstall black prettierd" \
    "+MasonInstall pyright lua_ls tsserver ruff" \
    "+TSUpdate lua vim vimdoc query python javascript typescript tsx json yaml html css bash markdown" \
    "+qa" || true
}

main() {
  msg "Installing prerequisites…"
  case "$(uname -s)" in
    Linux) install_prereqs_linux ;;
    Darwin) install_prereqs_macos ;;
    *) err "Unsupported OS"; exit 1 ;;
  esac

  msg "Preparing config directory…"
  if [ -e "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ]; then
    msg "Existing $CONFIG_DIR detected → backing up to $BACKUP_DIR"
    mv "$CONFIG_DIR" "$BACKUP_DIR"
  fi

  mkdir -p "$(dirname "$CONFIG_DIR")"
  ln -sfn "$SRC_DIR" "$CONFIG_DIR"
  msg "Linked $SRC_DIR → $CONFIG_DIR"

  postinstall_headless
  msg "$APP_NAME installed. Launch nvim and enjoy."
  printf "\nTips:\n- If icons look odd, install a Nerd Font (e.g., Hack Nerd Font) and set your terminal to use it.\n- Telescope live_grep requires ripgrep (installed).\n- TypeScript runner in your config references 'tsx'; install with: npm i -g tsx (optional).\n\n"
}

main "$@"
