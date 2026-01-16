# Goose Windows - Sync and Build Script
# This script syncs with upstream block/goose and optionally rebuilds

param(
    [switch]$Build,
    [switch]$Force,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Sync-Upstream {
    Write-Status "Fetching upstream..." "Cyan"

    # Ensure upstream remote exists
    $remotes = git remote
    if ($remotes -notcontains "upstream") {
        Write-Status "Adding upstream remote..." "Yellow"
        git remote add upstream https://github.com/block/goose.git
    }

    # Fetch upstream
    git fetch upstream main:refs/remotes/upstream/main 2>$null
    if ($LASTEXITCODE -ne 0) {
        git fetch upstream
    }

    # Check how far behind we are
    $behind = git rev-list --count HEAD..upstream/main 2>$null
    if ($behind -eq 0) {
        Write-Status "Already up to date with upstream!" "Green"
        return $false
    }

    Write-Status "Behind upstream by $behind commits" "Yellow"

    # Check for local changes
    $status = git status --porcelain
    if ($status) {
        Write-Status "Warning: You have uncommitted changes" "Yellow"
        if (-not $Force) {
            Write-Status "Use -Force to stash and continue, or commit your changes first" "Yellow"
            return $false
        }
        Write-Status "Stashing local changes..." "Yellow"
        git stash push -m "Auto-stash before upstream sync"
    }

    # Merge upstream
    Write-Status "Merging upstream changes..." "Cyan"
    git merge upstream/main --no-edit

    if ($LASTEXITCODE -ne 0) {
        Write-Status "Merge conflict! Please resolve manually." "Red"
        git merge --abort
        return $false
    }

    Write-Status "Successfully synced with upstream!" "Green"

    # Pull from origin to ensure we have latest
    git pull origin main --no-edit 2>$null

    # Push to origin
    Write-Status "Pushing to origin..." "Cyan"
    git push origin main

    return $true
}

function Build-Goose {
    Write-Status "Building Goose..." "Cyan"

    Push-Location $RepoRoot
    try {
        # Build Rust components
        Write-Status "Building Rust components..." "Cyan"
        cargo build --release

        if ($LASTEXITCODE -ne 0) {
            Write-Status "Rust build failed!" "Red"
            return $false
        }

        # Copy to local install
        $targetExe = "$RepoRoot\target\release\goosed.exe"
        $installDir = "$env:USERPROFILE\.goose\bin"

        if (Test-Path $targetExe) {
            if (-not (Test-Path $installDir)) {
                New-Item -ItemType Directory -Path $installDir -Force | Out-Null
            }

            Write-Status "Copying goosed.exe to $installDir..." "Cyan"
            Copy-Item $targetExe "$installDir\goosed.exe" -Force
            Write-Status "Build complete!" "Green"
        }

        return $true
    }
    finally {
        Pop-Location
    }
}

# Main execution
Push-Location $RepoRoot
try {
    Write-Status "=== Goose Windows Sync ===" "Magenta"
    Write-Status ""

    $synced = Sync-Upstream

    if ($Build -or $synced) {
        if ($synced) {
            Write-Status ""
            Write-Status "New changes detected, rebuilding..." "Yellow"
        }
        Build-Goose
    }

    Write-Status ""
    Write-Status "Done!" "Green"
}
finally {
    Pop-Location
}
