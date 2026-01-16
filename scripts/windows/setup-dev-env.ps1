# Windows Development Environment Setup for Goose
# Run this script once to set up your development environment

param(
    [switch]$InstallRust,
    [switch]$InstallNode,
    [switch]$InstallBuildTools,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host @"

  ____                       ____
 / ___| ___   ___  ___  ___ |  _ \  _____   __
| |  _ / _ \ / _ \/ __|/ _ \| | | |/ _ \ \ / /
| |_| | (_) | (_) \__ \  __/| |_| |  __/\ V /
 \____|\___/ \___/|___/\___||____/ \___| \_/

     Windows Development Environment Setup

"@ -ForegroundColor Magenta

if ($All) {
    $InstallRust = $true
    $InstallNode = $true
    $InstallBuildTools = $true
}

# Check for admin rights for some installations
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Function to check if a command exists
function Test-Command {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to download and run installer
function Install-FromUrl {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$Arguments = ""
    )

    $TempPath = Join-Path $env:TEMP $OutFile
    Write-Host "Downloading $Url..."
    Invoke-WebRequest -Uri $Url -OutFile $TempPath -UseBasicParsing
    Write-Host "Running installer..."

    if ($Arguments) {
        Start-Process -FilePath $TempPath -ArgumentList $Arguments -Wait
    } else {
        Start-Process -FilePath $TempPath -Wait
    }

    Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
}

# Install Visual Studio Build Tools
if ($InstallBuildTools) {
    Write-Host "`n==> Checking Visual Studio Build Tools..." -ForegroundColor Cyan

    $VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $HasBuildTools = $false

    if (Test-Path $VsWhere) {
        $Installations = & $VsWhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
        $HasBuildTools = $Installations.Count -gt 0
    }

    if (-not $HasBuildTools) {
        Write-Host "Visual Studio Build Tools not found. Installing..."

        if (-not $IsAdmin) {
            Write-Warning "Administrator rights required to install Build Tools."
            Write-Host "Please run this script as Administrator or install manually from:"
            Write-Host "https://visualstudio.microsoft.com/visual-cpp-build-tools/"
        } else {
            $BtUrl = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
            $TempPath = Join-Path $env:TEMP "vs_BuildTools.exe"

            Write-Host "Downloading Visual Studio Build Tools..."
            Invoke-WebRequest -Uri $BtUrl -OutFile $TempPath -UseBasicParsing

            Write-Host "Installing (this may take several minutes)..."
            Start-Process -FilePath $TempPath -ArgumentList `
                "--quiet", "--wait", "--norestart", `
                "--add", "Microsoft.VisualStudio.Workload.VCTools", `
                "--add", "Microsoft.VisualStudio.Component.Windows11SDK.22621", `
                "--includeRecommended" -Wait

            Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
            Write-Host "[OK] Visual Studio Build Tools installed" -ForegroundColor Green
        }
    } else {
        Write-Host "[OK] Visual Studio Build Tools already installed" -ForegroundColor Green
    }
}

# Install Rust
if ($InstallRust) {
    Write-Host "`n==> Checking Rust..." -ForegroundColor Cyan

    if (-not (Test-Command "rustc")) {
        Write-Host "Rust not found. Installing via rustup..."

        $RustupUrl = "https://win.rustup.rs/x86_64"
        $TempPath = Join-Path $env:TEMP "rustup-init.exe"

        Invoke-WebRequest -Uri $RustupUrl -OutFile $TempPath -UseBasicParsing

        # Install with MSVC toolchain as default
        & $TempPath -y --default-toolchain stable --default-host x86_64-pc-windows-msvc

        Remove-Item $TempPath -Force -ErrorAction SilentlyContinue

        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + $env:PATH

        Write-Host "[OK] Rust installed" -ForegroundColor Green
    } else {
        Write-Host "[OK] Rust already installed: $(rustc --version)" -ForegroundColor Green

        # Check if MSVC target is installed
        $Targets = rustup target list --installed
        if ($Targets -notcontains "x86_64-pc-windows-msvc") {
            Write-Host "Adding MSVC target..."
            rustup target add x86_64-pc-windows-msvc
        }
    }

    # Ensure we have the latest stable
    Write-Host "Updating Rust toolchain..."
    rustup update stable
}

# Install Node.js
if ($InstallNode) {
    Write-Host "`n==> Checking Node.js..." -ForegroundColor Cyan

    if (-not (Test-Command "node")) {
        Write-Host "Node.js not found. Installing..."

        # Install via winget if available, otherwise download directly
        if (Test-Command "winget") {
            winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        } else {
            $NodeVersion = "22.11.0"
            $NodeUrl = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-x64.msi"
            Install-FromUrl -Url $NodeUrl -OutFile "node-installer.msi" -Arguments "/quiet"
        }

        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + $env:PATH

        Write-Host "[OK] Node.js installed" -ForegroundColor Green
    } else {
        $NodeVersion = (node --version)
        Write-Host "[OK] Node.js already installed: $NodeVersion" -ForegroundColor Green

        # Check version
        $MajorVersion = [int]($NodeVersion -replace "v(\d+)\..*", '$1')
        if ($MajorVersion -lt 20) {
            Write-Warning "Node.js version $NodeVersion is older than recommended (v20+)"
            Write-Host "Consider updating: https://nodejs.org"
        }
    }
}

# Configure Git (if present)
Write-Host "`n==> Checking Git configuration..." -ForegroundColor Cyan

if (Test-Command "git") {
    Write-Host "[OK] Git installed: $(git --version)" -ForegroundColor Green

    # Set up useful git settings for Windows
    git config --global core.autocrlf true
    git config --global core.longpaths true

    Write-Host "[OK] Git configured for Windows (autocrlf=true, longpaths=true)" -ForegroundColor Green
} else {
    Write-Warning "Git not found. Please install Git for Windows from https://git-scm.com"
}

# Create development helper scripts
Write-Host "`n==> Creating helper scripts..." -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create a quick-build script
$QuickBuildScript = @'
# Quick build script - runs from repository root
param([switch]$Release)

$BuildType = if ($Release) { "release" } else { "debug" }
& "$PSScriptRoot\build-windows.ps1" -BuildType $BuildType
'@

$QuickBuildPath = Join-Path $ScriptDir "quick-build.ps1"
Set-Content -Path $QuickBuildPath -Value $QuickBuildScript
Write-Host "[OK] Created quick-build.ps1" -ForegroundColor Green

# Create a dev runner script
$DevRunScript = @'
# Development runner - builds and runs Goose UI
param([switch]$Release)

$RepoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$BuildType = if ($Release) { "release" } else { "debug" }

Write-Host "Building Goose ($BuildType)..." -ForegroundColor Cyan
& "$PSScriptRoot\build-windows.ps1" -BuildType $BuildType -SkipUI

Write-Host "Starting Goose UI..." -ForegroundColor Cyan
Push-Location "$RepoRoot\ui\desktop"
try {
    npm run start-gui
} finally {
    Pop-Location
}
'@

$DevRunPath = Join-Path $ScriptDir "dev-run.ps1"
Set-Content -Path $DevRunPath -Value $DevRunScript
Write-Host "[OK] Created dev-run.ps1" -ForegroundColor Green

# Summary
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan

Write-Host "`nInstalled components:"

if (Test-Command "rustc") {
    Write-Host "  [x] Rust $(rustc --version)" -ForegroundColor Green
}
if (Test-Command "node") {
    Write-Host "  [x] Node.js $(node --version)" -ForegroundColor Green
}
if (Test-Command "git") {
    Write-Host "  [x] Git $(git --version)" -ForegroundColor Green
}

Write-Host "`nNext steps:"
Write-Host "  1. Open a new terminal to refresh PATH"
Write-Host "  2. Navigate to the repository root"
Write-Host "  3. Run: .\scripts\windows\build-windows.ps1"
Write-Host ""
Write-Host "Quick commands:"
Write-Host "  .\scripts\windows\quick-build.ps1          # Debug build"
Write-Host "  .\scripts\windows\quick-build.ps1 -Release # Release build"
Write-Host "  .\scripts\windows\dev-run.ps1              # Build and run"
