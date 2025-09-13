#Requires -Version 5.1
param()
$ErrorActionPreference = 'Stop'


# Required: set REPO_SLUG like "ZaneHyatt/nvim-portable" in your one-liner
$REPO_SLUG = $env:REPO_SLUG
if (-not $REPO_SLUG -or $REPO_SLUG -like '*YOUR_GH_USERNAME*') { Write-Host '[error] Set REPO_SLUG env var (e.g., REPO_SLUG=ZaneHyatt/nvim-portable)' -ForegroundColor Red; exit 2 }
$BRANCH = $env:BRANCH; if (-not $BRANCH) { $BRANCH = 'main' }
$INSTALL_DIR = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA ("nvim-portable_" + ($REPO_SLUG -replace '/','_')) }


$Tmp = New-Item -ItemType Directory -Path ([IO.Path]::GetTempPath() + [IO.Path]::GetRandomFileName())
try {
Write-Host "==> Fetching $REPO_SLUG@$BRANCH…" -ForegroundColor Green
$tarUrl = "https://github.com/$REPO_SLUG/archive/refs/heads/$BRANCH.zip"
$zip = Join-Path $Tmp 'repo.zip'
Invoke-WebRequest -UseBasicParsing $tarUrl -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $Tmp
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
$repoName = ($REPO_SLUG.Split('/'))[-1]
$extracted = Get-ChildItem -Directory $Tmp | Where-Object { $_.Name -like "$repoName-*" } | Select-Object -First 1
Copy-Item -Path (Join-Path $extracted.FullName '*') -Destination $INSTALL_DIR -Recurse -Force


if (-not (Test-Path (Join-Path $INSTALL_DIR 'nvim/init.lua'))) { throw 'nvim/init.lua missing after download' }
Push-Location $INSTALL_DIR
& scripts/install.ps1
Pop-Location
}
finally {
Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}
