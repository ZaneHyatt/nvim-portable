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

# Guard: refuse to run unless we're next to nvim/init.lua
if [ ! -f "$SRC_DIR/init.lua" ]; then
  err "Couldn't find '$SRC_DIR/init.lua'. If you ran this via curl, use scripts/bootstrap.sh instead (see README)."
  exit 2
fi

# ---- Neovim version controls ----
# Set NVIM_VERSION to 'v0.12.0' (exact tag) or 'nightly' to download official binaries.
# If empty, we'll use your OS package manager's neovim.
NVIM_VERSION="${NVIM_VERSION:-}"

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "x86_64" ;; # fallback
  esac
}

install_nvim_tarball_linux() {
  local version="$1" arch="$(detect_arch)"
  local asset="nvim-linux-${arch}.tar.gz"
  local url instdir
  if [ "$version" = "nightly" ]; then
    url="https://github.com/neovim/neovim/releases/download/nightly/${asset}"
    instdir="${HOME}/.local/neovim-nightly"
  else
    url="https://github.com/neovim/neovim/releases/download/${version}/${asset}"
    instdir="${HOME}/.local/neovim-${version}"
  fi

  msg "Installing Neovim $version ($arch) to $instdir"
  mkdir -p "$instdir"
  curl -fL "$url" -o /tmp/nvim.tgz
  tar xzf /tmp/nvim.tgz -C "$instdir" --strip-components=1

  mkdir -p "${HOME}/.local/bin"
  ln -sfn "$instdir/bin/nvim" "${HOME}/.local/bin/nvim"

  # ensure ~/.local/bin on PATH for bash/zsh (idempotent)
  grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
  grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "${HOME}/.zshrc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc" || true
}

install_nvim_tarball_macos() {
  local version="$1" arch="$(detect_arch)"
  local mac_asset
  if [ "$arch" = "arm64" ]; then mac_asset="nvim-macos-arm64.tar.gz"; else mac_asset="nvim-macos-x86_64.tar.gz"; fi
  local url instdir
  if [ "$version" = "nightly" ]; then
    url="https://github.com/neovim/neovim/releases/download/nightly/${mac_asset}"
    instdir="${HOME}/.local/neovim-nightly"
  else
    url="https://github.com/neovim/neovim/releases/download/${version}/${mac_asset}"
    instdir="${HOME}/.local/neovim-${version}"
  fi

  msg "Installing Neovim $version ($arch) to $instdir"
  mkdir -p "$instdir"
  curl -fL "$url" -o /tmp/nvim.tgz
  tar xzf /tmp/nvim.tgz -C "$instdir" --strip-components=1

  mkdir -p "${HOME}/.local/bin"
  ln -sfn "$instdir/bin/nvim" "${HOME}/.local/bin/nvim"

  # ensure ~/.local/bin on PATH for common shells
  for f in "${HOME}/.zprofile" "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
    [ -f "$f" ] && grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$f" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$f"
  done
}

install_prereqs_linux() {
  if have apt; then
    sudo apt update
    sudo apt install -y git curl ripgrep fd-find unzip build-essential python3 python3-pip nodejs npm
    # fd is 'fdfind' on Debian/Ubuntu; alias to 'fd' if needed
    if ! have fd && have fdfind; then sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true; fi
    [ -z "${NVIM_VERSION}" ] && sudo apt install -y neovim || true
  elif have dnf; then
    sudo dnf install -y git curl ripgrep fd-find unzip @development-tools python3 python3-pip nodejs npm
    [ -z "${NVIM_VERSION}" ] && sudo dnf install -y neovim || true
  elif have pacman; then
    sudo pacman -Syu --noconfirm git curl ripgrep fd unzip base-devel python python-pip nodejs npm
    [ -z "${NVIM_VERSION}" ] && sudo pacman -S --noconfirm neovim || true
  else
    err "Unsupported Linux distro. Please install: git curl ripgrep fd unzip build tools python3 nodejs npm (and optionally neovim)."
    exit 1
  fi
}

install_prereqs_macos() {
  if ! have brew; then
    msg "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$([ -f /opt/homebrew/bin/brew ] && echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' || echo 'eval \"$(/usr/local/bin/brew shellenv)\"')"
  fi
  brew update
  brew install git ripgrep fd unzip node python
  [ -z "${NVIM_VERSION}" ] && brew install neovim || true
}

postinstall_headless() {
  msg "Bootstrapping plugins, LSPs, Treesitter (headless)…"
  nvim --headless \
    "+Lazy! sync" \
    "+MasonInstall black prettierd pyright lua_ls ruff typescript-language-server" \
    "+TSUpdate lua vim vimdoc query python javascript typescript tsx json yaml html css bash markdown" \
    "+qa" || true
}

main() {
  msg "Installing prerequisites…"
  case "$(uname -s)" in
    Linux)
      install_prereqs_linux
      [ -n "${NVIM_VERSION}" ] && install_nvim_tarball_linux "${NVIM_VERSION}"
      ;;
    Darwin)
      install_prereqs_macos
      [ -n "${NVIM_VERSION}" ] && install_nvim_tarball_macos "${NVIM_VERSION}"
      ;;
    *) err "Unsupported OS"; exit 1 ;;
  esac

  # Ensure the just-installed nvim is on PATH for this shell session too
  export PATH="$HOME/.local/bin:$PATH"

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
  printf "\nTips:\n- If icons look odd, install a Nerd Font (e.g., Hack Nerd Font) and set your terminal to use it.\n- Telescope live_grep requires ripgrep (installed).\n- Optional TypeScript runner: npm i -g tsx.\n\n"
}

main "$@"
