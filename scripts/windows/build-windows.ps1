# Windows Native Build Script for Goose
# This script builds Goose using the native MSVC toolchain for optimal Windows performance

param(
    [ValidateSet("debug", "release")]
    [string]$BuildType = "release",

    [switch]$SkipRust,
    [switch]$SkipUI,
    [switch]$CleanBuild,
    [switch]$Package,
    [switch]$Sign,

    [string]$CertificateFile = $env:WINDOWS_CERTIFICATE_FILE,
    [string]$CertificatePassword = $env:WINDOWS_CERTIFICATE_PASSWORD
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Script configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path "$ScriptDir\..\..").Path
$TargetDir = Join-Path $RepoRoot "target"
$UIDir = Join-Path $RepoRoot "ui\desktop"
$BinDir = Join-Path $UIDir "src\bin"

# Colors for output
function Write-Step { param($Message) Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Failure { param($Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

# Banner
Write-Host @"

  ____                       __        ___           _
 / ___| ___   ___  ___  ___  \ \      / (_)_ __   __| | _____      _____
| |  _ / _ \ / _ \/ __|/ _ \  \ \ /\ / /| | '_ \ / _` |/ _ \ \ /\ / / __|
| |_| | (_) | (_) \__ \  __/   \ V  V / | | | | | (_| | (_) \ V  V /\__ \
 \____|\___/ \___/|___/\___|    \_/\_/  |_|_| |_|\__,_|\___/ \_/\_/ |___/

                    Native Windows Build System
"@ -ForegroundColor Magenta

Write-Host "Build Type: $BuildType" -ForegroundColor White
Write-Host "Repository: $RepoRoot" -ForegroundColor White
Write-Host ""

# Check prerequisites
Write-Step "Checking prerequisites..."

# Check for Rust
if (-not (Get-Command "rustc" -ErrorAction SilentlyContinue)) {
    Write-Failure "Rust is not installed. Please install from https://rustup.rs"
    exit 1
}

$RustVersion = (rustc --version)
Write-Success "Rust: $RustVersion"

# Check for MSVC toolchain
$RustTarget = (rustc -vV | Select-String "host:").ToString().Split(":")[1].Trim()
if ($RustTarget -notlike "*msvc*") {
    Write-Warning "Not using MSVC toolchain. For optimal Windows builds, install Visual Studio Build Tools."
    Write-Host "Current target: $RustTarget"

    # Check if MSVC target is available
    $MsvcTarget = "x86_64-pc-windows-msvc"
    $Targets = rustup target list --installed
    if ($Targets -contains $MsvcTarget) {
        Write-Host "MSVC target available, will use: $MsvcTarget"
        $env:CARGO_BUILD_TARGET = $MsvcTarget
    }
}

# Check for Node.js
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Failure "Node.js is not installed. Please install Node.js 24+"
    exit 1
}

$NodeVersion = (node --version)
Write-Success "Node.js: $NodeVersion"

# Check for npm
if (-not (Get-Command "npm" -ErrorAction SilentlyContinue)) {
    Write-Failure "npm is not installed."
    exit 1
}

Write-Success "npm: $(npm --version)"

# Clean build if requested
if ($CleanBuild) {
    Write-Step "Cleaning previous build artifacts..."

    if (Test-Path $TargetDir) {
        Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned target directory"
    }

    if (Test-Path $BinDir) {
        Get-ChildItem -Path $BinDir -Include "*.exe","*.dll" -Recurse | Remove-Item -Force
        Write-Success "Cleaned UI bin directory"
    }

    $NodeModules = Join-Path $UIDir "node_modules"
    if (Test-Path $NodeModules) {
        Remove-Item -Path $NodeModules -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Cleaned node_modules"
    }
}

# Build Rust binaries
if (-not $SkipRust) {
    Write-Step "Building Rust binaries ($BuildType)..."

    Push-Location $RepoRoot
    try {
        $CargoArgs = @("build")

        if ($BuildType -eq "release") {
            $CargoArgs += "--release"
        }

        # Add Windows-specific optimizations for release builds
        if ($BuildType -eq "release") {
            $env:RUSTFLAGS = "-C target-feature=+crt-static -C opt-level=3"
        }

        Write-Host "Running: cargo $($CargoArgs -join ' ')"
        & cargo @CargoArgs

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "Cargo build failed with exit code $LASTEXITCODE"
            exit $LASTEXITCODE
        }

        Write-Success "Rust build completed"

        # Generate OpenAPI schema
        Write-Step "Generating OpenAPI schema..."
        & cargo run -p goose-server --bin generate_schema

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "OpenAPI schema generation failed, continuing..."
        } else {
            Write-Success "OpenAPI schema generated"
        }
    }
    finally {
        Pop-Location
    }
}

# Copy binaries to UI directory
Write-Step "Copying binaries to UI directory..."

$BuildDir = if ($BuildType -eq "release") { "release" } else { "debug" }
$SourceDir = Join-Path $TargetDir $BuildDir

# Ensure bin directory exists
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# Copy executables
$Executables = @("goosed.exe", "goose.exe")
foreach ($Exe in $Executables) {
    $Source = Join-Path $SourceDir $Exe
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $BinDir -Force
        Write-Success "Copied $Exe"
    } else {
        Write-Warning "$Exe not found at $Source"
    }
}

# Copy any required DLLs (for MinGW builds)
$Dlls = Get-ChildItem -Path $SourceDir -Filter "*.dll" -ErrorAction SilentlyContinue
foreach ($Dll in $Dlls) {
    Copy-Item -Path $Dll.FullName -Destination $BinDir -Force
    Write-Success "Copied $($Dll.Name)"
}

# Build UI
if (-not $SkipUI) {
    Write-Step "Building Electron UI..."

    Push-Location $UIDir
    try {
        # Install dependencies
        Write-Host "Installing npm dependencies..."
        & npm ci

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "npm ci failed, trying npm install..."
            & npm install
        }

        # Generate API client
        Write-Host "Generating API client..."
        & npm run generate-api

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "API generation failed, continuing..."
        }

        # Build or package based on flag
        if ($Package) {
            Write-Host "Creating distributable package..."

            # Set environment for Windows build
            $env:ELECTRON_PLATFORM = "win32"

            & npm run make -- --platform=win32 --arch=x64

            if ($LASTEXITCODE -ne 0) {
                Write-Failure "Package creation failed"
                exit $LASTEXITCODE
            }

            Write-Success "Package created in out/ directory"

            # Sign if requested
            if ($Sign -and $CertificateFile) {
                Write-Step "Signing executables..."

                $OutDir = Join-Path $UIDir "out"
                $ExesToSign = Get-ChildItem -Path $OutDir -Filter "*.exe" -Recurse

                foreach ($ExeFile in $ExesToSign) {
                    Write-Host "Signing $($ExeFile.Name)..."

                    $SignToolArgs = @(
                        "sign",
                        "/f", $CertificateFile,
                        "/fd", "sha256",
                        "/tr", "http://timestamp.digicert.com",
                        "/td", "sha256"
                    )

                    if ($CertificatePassword) {
                        $SignToolArgs += @("/p", $CertificatePassword)
                    }

                    $SignToolArgs += $ExeFile.FullName

                    & signtool @SignToolArgs

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "Signed $($ExeFile.Name)"
                    } else {
                        Write-Warning "Failed to sign $($ExeFile.Name)"
                    }
                }
            }
        } else {
            Write-Host "Building UI (no packaging)..."
            & npm run package

            if ($LASTEXITCODE -ne 0) {
                Write-Failure "UI build failed"
                exit $LASTEXITCODE
            }
        }

        Write-Success "UI build completed"
    }
    finally {
        Pop-Location
    }
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "BUILD COMPLETE" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan

Write-Host "`nBuild artifacts:"
Write-Host "  Rust binaries: $SourceDir"
Write-Host "  UI binaries:   $BinDir"

if ($Package) {
    $OutDir = Join-Path $UIDir "out"
    Write-Host "  Packages:      $OutDir"

    # List created packages
    if (Test-Path $OutDir) {
        Write-Host "`nCreated packages:"
        Get-ChildItem -Path $OutDir -Filter "*.exe" -Recurse | ForEach-Object {
            $Size = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name) ($Size MB)"
        }
        Get-ChildItem -Path $OutDir -Filter "*.zip" -Recurse | ForEach-Object {
            $Size = [math]::Round($_.Length / 1MB, 2)
            Write-Host "  - $($_.Name) ($Size MB)"
        }
    }
}

Write-Host "`nTo run Goose:"
Write-Host "  cd $UIDir && npm run start-gui"
