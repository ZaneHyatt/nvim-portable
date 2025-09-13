#Requires -Version 5.1
param()
$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "==> $msg" -ForegroundColor Green }
function Write-Err($msg){ Write-Host "[error] $msg" -ForegroundColor Red }
function Have($name){ $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

# Resolve repo root (this script lives in scripts/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$SrcDir    = Join-Path $RepoRoot 'nvim'
$ConfigDir = Join-Path $env:LOCALAPPDATA 'nvim'
$BackupDir = Join-Path $env:LOCALAPPDATA ("nvim.backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))

# Guard: refuse to run unless we're next to nvim/init.lua
if (-not (Test-Path (Join-Path $SrcDir 'init.lua'))) {
  Write-Err "Couldn't find 'nvim/init.lua' next to this script. If you ran this via web one-liner, use scripts/bootstrap.ps1 instead (see README)."
  exit 2
}

# Optional pin: 'v0.12.0' or 'nightly'
$EnvNVIM_VERSION = $env:NVIM_VERSION

function Install-Prereqs {
  $installNeovim = [string]::IsNullOrEmpty($EnvNVIM_VERSION)
  if (Have 'winget') {
    Write-Info 'Installing prerequisites with winget…'
    $ids = @('Git.Git','BurntSushi.ripgrep.MSVC','sharkdp.fd','Python.Python.3','OpenJS.NodeJS.LTS')
    if ($installNeovim) { $ids = @('Neovim.Neovim') + $ids }
    foreach ($id in $ids){
      try { winget install --id $id -e --accept-package-agreements --accept-source-agreements --silent } catch { }
    }
  } elseif (Have 'choco') {
    Write-Info 'Installing prerequisites with Chocolatey…'
    choco install -y git ripgrep fd python nodejs-lts
    if ($installNeovim) { choco install -y neovim }
  } else {
    Write-Err 'No winget or choco found. Install: neovim (optional when NVIM_VERSION set), git, ripgrep, fd, python, nodejs.'
  }
}

function Install-NeovimZip {
  param([string]$Version)

  $arch = 'win64'  # change to 'winarm64' if you specifically want ARM Windows builds
  if ($Version -eq 'nightly') {
    $asset = "nvim-$arch.zip"
    $url   = "https://github.com/neovim/neovim/releases/download/nightly/$asset"
    $inst  = Join-Path $env:LOCALAPPDATA "neovim-nightly"
  } else {
    $asset = "nvim-$arch.zip"
    $url   = "https://github.com/neovim/neovim/releases/download/$Version/$asset"
    $inst  = Join-Path $env:LOCALAPPDATA "neovim-$Version"
  }

  Write-Info "Installing Neovim $Version ($arch) to $inst"
  New-Item -ItemType Directory -Force -Path $inst | Out-Null
  $zip = Join-Path $env:TEMP "nvim.zip"
  Invoke-WebRequest -UseBasicParsing $url -OutFile $zip
  Expand-Archive -Path $zip -DestinationPath $inst -Force

  # Add …\bin to PATH (idempotent)
  $bin = Join-Path $inst "bin"
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($current -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$bin;$current", "User")
    $env:Path = "$bin;$env:Path"
  }
}

function New-DirLink($LinkPath, $TargetPath){
  if (Test-Path $LinkPath) { Remove-Item $LinkPath -Recurse -Force }
  # Prefer NTFS junction (no admin required)
  $parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
  $cmd = "mklink /J `"$LinkPath`" `"$TargetPath`""
  $p = Start-Process -FilePath cmd.exe -ArgumentList "/c", $cmd -Wait -PassThru -WindowStyle Hidden
  if ($p.ExitCode -ne 0) {
    Write-Err "mklink failed; falling back to copying files."
    Copy-Item $TargetPath $LinkPath -Recurse -Force
  }
}

Write-Info 'Installing prerequisites…'
Install-Prereqs
if ($EnvNVIM_VERSION) {
  Install-NeovimZip -Version $EnvNVIM_VERSION
}

Write-Info "Preparing config directory at $ConfigDir"
if (Test-Path $ConfigDir) {
  $isLink = (Get-Item $ConfigDir).Attributes -band [IO.FileAttributes]::ReparsePoint
  if (-not $isLink) {
    Write-Info "Existing config detected → backing up to $BackupDir"
    Move-Item $ConfigDir $BackupDir
  } else {
    Remove-Item $ConfigDir -Force
  }
}

Write-Info "Linking $SrcDir → $ConfigDir"
New-DirLink -LinkPath $ConfigDir -TargetPath $SrcDir

Write-Info 'Bootstrapping plugins, LSPs, Treesitter (headless)…'
try {
  nvim --headless `
       "+Lazy! sync" `
       "+MasonInstall black prettierd pyright lua_ls ruff typescript-language-server" `
       "+TSUpdate lua vim vimdoc query python javascript typescript tsx json yaml html css bash markdown" `
       "+qa"
} catch {
  Write-Err "Headless bootstrap failed. Open Neovim once and run :Lazy sync"
}

Write-Host "`nAll set. Launch Neovim and enjoy!" -ForegroundColor Green
Write-Host "Tips:`n- If icons look odd, install a Nerd Font (e.g., Hack Nerd Font) and set your terminal to use it.`n- Optional TS runner uses 'tsx': npm i -g tsx" -ForegroundColor Gray
