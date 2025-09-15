#Requires -Version 5.1
param()
$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "==> $msg" -ForegroundColor Green }
function Write-Err($msg){ Write-Host "[error] $msg" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir
$SrcDir    = Join-Path $RepoRoot 'nvim'
$ConfigDir = Join-Path $env:LOCALAPPDATA 'nvim'
$BackupDir = Join-Path $env:LOCALAPPDATA ("nvim.backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Have($name){ $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

function Install-Prereqs {
  if (Have 'winget') {
    Write-Info 'Installing prerequisites with winget…'
    $ids = @(
      'Neovim.Neovim',
      'Git.Git',
      'BurntSushi.ripgrep.MSVC',
      'sharkdp.fd',
      'Python.Python.3',
      'OpenJS.NodeJS.LTS'
    )
    foreach ($id in $ids){
      try { winget install --id $id -e --accept-package-agreements --accept-source-agreements --silent } catch { }
    }
  } elseif (Have 'choco') {
    Write-Info 'Installing prerequisites with Chocolatey…'
    choco install -y neovim git ripgrep fd python nodejs-lts
  } else {
    Write-Err 'No winget or choco found. Install neovim, git, ripgrep, fd, python, nodejs manually.'
  }
}

function New-DirLink($LinkPath, $TargetPath){
  if (Test-Path $LinkPath) { Remove-Item $LinkPath -Recurse -Force }
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
  nvim --headless "+Lazy! sync" `
       "+MasonInstall black prettierd" `
       "+MasonInstall pyright lua_ls tsserver ruff" `
       "+TSUpdate lua vim vimdoc query python javascript typescript tsx json yaml html css bash markdown" `
       "+qa"
} catch {
  Write-Err "Headless bootstrap failed. Open Neovim once and run :Lazy sync"
}

Write-Host "`nAll set. Launch Neovim and enjoy!" -ForegroundColor Green
Write-Host "Tips:`n- If icons look odd, install a Nerd Font (e.g., Hack Nerd Font) and set your terminal to use it.`n- Optional TS runner uses 'tsx': npm i -g tsx" -ForegroundColor Gray
