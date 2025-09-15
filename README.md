# Neovim – Portable Install (macOS, Linux, Windows, WSL)

Turnkey installer for my Neovim setup. It links this repo’s `nvim/` to the correct config path, installs common tools, then bootstraps plugins, LSPs, and Treesitter headlessly.

## Quick install (choose your OS)

## Quick install (safer bootstrap method)


### macOS / Linux / WSL
```bash
REPO_SLUG=YOUR_GH_USERNAME/YOUR_REPO_NAME \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_GH_USERNAME/YOUR_REPO_NAME/main/scripts/bootstrap.sh)"
```

### Windows (PowerShell)
**Option A: run directly from the web**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/YOUR_GH_USERNAME/YOUR_REPO_NAME/main/scripts/install.ps1).Content | Invoke-Expression"
```
**Option B: download then run**
```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/YOUR_GH_USERNAME/YOUR_REPO_NAME/main/scripts/install.ps1 -OutFile install.ps1
./install.ps1
```

### WSL
Open your WSL shell and run the Linux command above. It installs to `~/.config/nvim` *inside WSL*. Native Windows Neovim uses `%LOCALAPPDATA%\nvim`.

## What it installs
- Neovim, git, ripgrep, fd, unzip, build tools, Node, Python
- Plugins via [lazy.nvim]
- LSPs & tools via Mason: `pyright`, `lua_ls`, `tsserver`, `ruff`, `black`, `prettierd`
- Treesitter grammars for Lua, Python, JS/TS, TSX, JSON, YAML, HTML, CSS, Bash, Markdown

## Update / lock
```bash
make update
make lock       # pins plugin versions (creates lazy-lock.json)
```

## Uninstall
```bash
make uninstall  # removes ~/.config/nvim (symlink); backups untouched
```

## Notes
- If icons look weird, set your terminal to a **Nerd Font** (e.g., *Hack Nerd Font*).
- Optional TypeScript runner used by my config: `npm i -g tsx`.
- First run: `nvim` → everything should be ready.

## License
MIT (or whatever you prefer)

[lazy.nvim]: https://github.com/folke/lazy.nvim

### Custom Zane Install

## Linux / WSL
```bash
REPO_SLUG=ZaneHyatt/nvim-portable \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZaneHyatt/nvim-portable/main/scripts/bootstrap.sh)" && \
cd ~ && \
wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz && \
mkdir -p ~/.local/neovim-nightly && \
tar xzf nvim-linux-x86_64.tar.gz -C ~/.local/neovim-nightly --strip-components=1 && \
echo 'export PATH="$HOME/.local/neovim-nightly/bin:$PATH"' >> ~/.bashrc && \
source ~/.bashrc && \
sudo apt install -y python3-venv ca-certificates
```

## MacOS
```bash
REPO_SLUG=ZaneHyatt/nvim-portable && \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZaneHyatt/nvim-portable/main/scripts/bootstrap.sh)" && \
ARCH="$(uname -m)" && \
NVIM_TAR="$([ "$ARCH" = "arm64" ] && echo nvim-macos-arm64.tar.gz || echo nvim-macos-x86_64.tar.gz)" && \
cd ~ && \
curl -fsSLo "$NVIM_TAR" "https://github.com/neovim/neovim/releases/download/nightly/$NVIM_TAR" && \
mkdir -p ~/.local/neovim-nightly && \
tar xzf "$NVIM_TAR" -C ~/.local/neovim-nightly --strip-components=1 && \
rm -f "$NVIM_TAR" && \
RC_FILE="$([ -n "$ZSH_VERSION" ] && echo ~/.zshrc || echo ~/.bashrc)" && \
echo 'export PATH="$HOME/.local/neovim-nightly/bin:$PATH"' >> "$RC_FILE" && \
. "$RC_FILE" && \
/usr/bin/python3 -m ensurepip --upgrade && \
/usr/bin/python3 -m pip install --user --upgrade pip pynvim
```

Make sure to then enter ":Lazy sync" once in nvim
