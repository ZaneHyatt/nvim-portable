#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Neovim portable config (macOS)"
CONFIG_DIR="$HOME/.config/nvim"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SRC_DIR="$REPO_ROOT/nvim"
BACKUP_DIR="$HOME/.config/nvim.backup-$(date +%Y%m%d-%H%M%S)"

msg() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# Guard: must be run from inside the repo (script lives in scripts/)
if [ ! -f "$SRC_DIR/init.lua" ]; then
  err "Couldn't find '$SRC_DIR/init.lua'. If you want a web one-liner, use scripts/bootstrap.macos.sh instead."
  exit 2
fi

# ---- Optional Neovim pin ----
# Set NVIM_VERSION to 'v0.12.0' or 'nightly' to fetch official tarball.
# If empty, we'll brew-install neovim.
NVIM_VERSION="${NVIM_VERSION:-}"

detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64)  echo "x86_64" ;;
    *)             echo "x86_64" ;; # fallback
  esac
}

install_prereqs_macos() {
  if ! have brew; then
    msg "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$([ -f /opt/homebrew/bin/brew ] && echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' || echo 'eval \"$(/usr/local/bin/brew shellenv)\"')"
  else
    # Ensure brew env is in this shell
    eval "$([ -f /opt/homebrew/bin/brew ] && echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' || echo 'eval \"$(/usr/local/bin/brew shellenv)\"')"
  fi
  brew update
  # Core developer tools (skip brew neovim if pinning)
  brew install git ripgrep fd unzip node python
  [ -z "${NVIM_VERSION}" ] && brew install neovim || true
}

install_nvim_tarball_macos() {
  local version="$1"
  local arch="$(detect_arch)"
  local asset
  if [ "$arch" = "arm64" ]; then asset="nvim-macos-arm64.tar.gz"; else asset="nvim-macos-x86_64.tar.gz"; fi

  local url instdir
  if [ "$version" = "nightly" ]; then
    url="https://github.com/neovim/neovim/releases/download/nightly/${asset}"
    instdir="${HOME}/.local/neovim-nightly"
  else
    url="https://github.com/neovim/neovim/releases/download/${version}/${asset}"
    instdir="${HOME}/.local/neovim-${version}"
  fi

  msg "Installing Neovim $version ($arch) → $instdir"
  mkdir -p "$instdir"
  curl -fL "$url" -o /tmp/nvim.tgz
  tar xzf /tmp/nvim.tgz -C "$instdir" --strip-components=1

  mkdir -p "$HOME/.local/bin"
  ln -sfn "$instdir/bin/nvim" "$HOME/.local/bin/nvim"

  # Make sure ~/.local/bin is on PATH for zsh/bash logins
  for f in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile"; do
    [ -f "$f" ] && grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$f" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$f"
  done

  # Also in THIS shell
  export PATH="$HOME/.local/bin:$PATH"
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
  msg "Installing prerequisites (Homebrew)…"
  install_prereqs_macos
  [ -n "${NVIM_VERSION}" ] && install_nvim_tarball_macos "${NVIM_VERSION}"

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
  printf "\nTips:\n- If icons look odd, set a Nerd Font in your terminal.\n- Optional TypeScript runner: npm i -g tsx\n\n"
}

main "$@"
