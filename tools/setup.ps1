<#
.SYNOPSIS
    Sets up this project on Windows.

.DESCRIPTION
    Installs Git (with winget) and Rokit when they are missing, installs the tools pinned in
    rokit.toml (Rojo, Selene, StyLua, Wally), installs the Rojo plugin for Roblox Studio and the
    recommended VS Code extensions, builds the place to check the project, and can start
    `rojo serve`. Safe to run again: each step skips what is already in place.

.PARAMETER NoServe
    Do not offer to start `rojo serve` at the end.

.EXAMPLE
    tools\setup.cmd
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup.ps1 -NoServe
#>
[CmdletBinding()]
param(
    [switch]$NoServe
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$RepoUrl = 'https://github.com/ddmelo0104/roblox-rpg-game'
$RokitInstaller = 'https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1'
$RokitBin = Join-Path $HOME '.rokit\bin'
$PlaceFile = 'roblox-rpg-game.rbxl'

function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "    ok: $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "    warning: $Message" -ForegroundColor Yellow
}

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Adds the PATH saved in the registry to this window, so programs installed by this script are
# found without opening a new window.
function Update-SessionPath {
    $machine = [string][Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [string][Environment]::GetEnvironmentVariable('Path', 'User')
    $saved = [Environment]::ExpandEnvironmentVariables("$machine;$user")
    $env:Path = "$RokitBin;$env:Path;$saved"
}

Set-Location $ProjectRoot
Write-Host "Setting up $ProjectRoot"
Update-SessionPath

# 1. Git: needed to receive updates and send changes; the game itself runs without it.
Write-Step 'Git'
if (-not (Test-Command 'git') -and (Test-Command 'winget')) {
    Write-Host '    installing Git with winget...'
    winget install --id Git.Git --exact --silent --accept-source-agreements --accept-package-agreements
    Update-SessionPath
}
if (Test-Command 'git') {
    Write-Ok (git --version)
    if (-not (Test-Path (Join-Path $ProjectRoot '.git'))) {
        Write-Warn "this folder is not a git clone; to receive updates, clone $RepoUrl instead"
    }
} else {
    Write-Warn 'Git is not installed; get it from https://git-scm.com to receive updates'
}

# 2. Rokit, the tool manager of the project.
Write-Step 'Rokit (tool manager)'
if (-not (Test-Command 'rokit')) {
    Write-Host '    installing Rokit...'
    # A separate PowerShell runs the official installer, so the installer cannot end this script.
    # TLS 1.2 is set explicitly because older Windows PowerShell versions may not use it by default.
    $installCommand = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " +
        "Invoke-RestMethod '$RokitInstaller' | Invoke-Expression"
    powershell -NoProfile -ExecutionPolicy Bypass -Command $installCommand
    Update-SessionPath
}
if (-not (Test-Command 'rokit')) {
    throw 'Rokit is still missing after the install. Open a new PowerShell window and run this script again.'
}
Write-Ok (rokit --version)

# 3. The tools pinned in rokit.toml.
Write-Step 'Project tools (rokit.toml)'
rokit install --no-trust-check
if ($LASTEXITCODE -ne 0) {
    Write-Warn 'retrying without --no-trust-check; answer "y" if Rokit asks to trust a tool'
    rokit install
    if ($LASTEXITCODE -ne 0) {
        throw 'rokit install failed.'
    }
}
foreach ($tool in 'rojo', 'selene', 'stylua') {
    if (-not (Test-Command $tool)) {
        throw "$tool was not installed by Rokit."
    }
}
Write-Ok (rojo --version)

# 4. The Rojo plugin, which connects Roblox Studio to `rojo serve`.
Write-Step 'Rojo plugin for Roblox Studio'
rojo plugin install
if ($LASTEXITCODE -eq 0) {
    Write-Ok 'installed (restart Roblox Studio if it is open)'
} else {
    Write-Warn 'could not install it; inside Studio, get "Rojo" from the Creator Store instead'
}

# 5. Building the place checks default.project.json and every file under src/.
Write-Step 'Build the place'
rojo build -o $PlaceFile
if ($LASTEXITCODE -ne 0) {
    throw 'rojo build failed.'
}
Write-Ok $PlaceFile

# 6. Editor extensions recommended by the project.
Write-Step 'VS Code extensions (.vscode/extensions.json)'
if (Test-Command 'code') {
    $extensionsFile = Join-Path $ProjectRoot '.vscode\extensions.json'
    $extensions = (Get-Content $extensionsFile -Raw | ConvertFrom-Json).recommendations
    foreach ($id in $extensions) {
        code --install-extension $id --force | Out-Null
    }
    Write-Ok ($extensions -join ', ')
} else {
    Write-Warn 'VS Code was not found (the "code" command); skipping'
}

# 7. Python only regenerates docs/planejamento/BACKLOG.md; the game does not need it.
Write-Step 'Python (only for tools/backlog.py)'
if ((Test-Command 'py') -or (Test-Command 'python')) {
    Write-Ok 'found'
} else {
    Write-Warn 'not found; only needed to regenerate the backlog'
}

# 8. Roblox Studio itself.
Write-Step 'Roblox Studio'
$studioFolders = @(Join-Path $env:LOCALAPPDATA 'Roblox\Versions')
if (${env:ProgramFiles(x86)}) {
    $studioFolders += Join-Path ${env:ProgramFiles(x86)} 'Roblox\Versions'
}
$studio = Get-ChildItem -Path $studioFolders -Filter 'RobloxStudioBeta.exe' -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($studio) {
    Write-Ok $studio.FullName
} else {
    Write-Warn 'not found; install it from https://create.roblox.com'
}

Write-Step 'Done'
Write-Host @'
Next steps:
  1. Open Roblox Studio and create a place from the Baseplate template.
  2. Plugins tab > Rojo > Connect (default address: localhost:34872).
  3. Press Play. The Output shows "[Main] server ok" and "[Main] client ok".
  The test steps of each story are in docs/planejamento/historias.
'@

if (-not $NoServe) {
    $answer = Read-Host 'Start "rojo serve" now? [Y/n]'
    if ($answer -notmatch '^\s*n') {
        Write-Host 'Serving the project. Keep this window open while you use Studio; Ctrl+C stops it.'
        rojo serve
    }
}
