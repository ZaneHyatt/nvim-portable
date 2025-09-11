# Neovim – Portable Install (macOS, Linux, Windows, WSL)

Turnkey installer for my Neovim setup. It links this repo’s `nvim/` to the correct config path, installs common tools, then bootstraps plugins, LSPs, and Treesitter headlessly.

## Quick install (choose your OS)

### macOS / Linux
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_GH_USERNAME/YOUR_REPO_NAME/main/scripts/install.sh)"
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
