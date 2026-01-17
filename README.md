<div align="center">

# Goose for Windows

_A Windows-optimized fork of [Block's Goose](https://github.com/block/goose) AI agent_

<p align="center">
  <a href="https://opensource.org/licenses/Apache-2.0">
    <img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg">
  </a>
  <a href="https://github.com/dustin-olenslager/goose-windows/releases/latest">
    <img src="https://img.shields.io/github/v/release/dustin-olenslager/goose-windows?label=Download" alt="Latest Release">
  </a>
  <a href="https://discord.gg/goose-oss">
    <img src="https://img.shields.io/discord/1287729918100246654?logo=discord&logoColor=white&label=Discord&color=blueviolet" alt="Discord">
  </a>
</p>
</div>

## Why This Fork?

This fork provides a **native Windows experience** for Goose, the open source AI agent that automates engineering tasks. While the upstream project primarily targets macOS and Linux, this fork adds:

- **Native Windows 11 Title Bar** - Proper minimize, maximize, and close controls
- **One-Click Auto-Updates** - Check for updates in Settings and install with a single click
- **Squirrel-based Installer** - Professional Windows installer with automatic updates
- **MSVC Toolchain** - Native Microsoft Visual C++ builds for optimal Windows performance
- **Claude CLI Provider Fix** - Correct subprocess handling on Windows
- **Automatic Upstream Sync** - Stays up-to-date with block/goose every 4 hours

## Quick Start

### Download

**[Download Latest Release](https://github.com/dustin-olenslager/goose-windows/releases/latest)**

| File | Description |
|------|-------------|
| `Goose-X.X.X-Setup.exe` | Windows installer with auto-updates (recommended) |
| `Goose-win32-x64-X.X.X.zip` | Portable version |

### Install

1. Download `Goose-X.X.X-Setup.exe` from the latest release
2. Run the installer
3. Goose installs to `%LOCALAPPDATA%\Goose`
4. Launch from Start Menu

### Update

The app automatically checks for updates. To manually update:

1. Open Goose
2. Go to **Settings** (sidebar) → **App** tab
3. Click **Check for Updates**
4. Click **Install & Restart** when available

## What is Goose?

Goose is your on-machine AI agent, capable of automating complex development tasks from start to finish. More than just code suggestions, goose can:

- Build entire projects from scratch
- Write and execute code
- Debug failures
- Orchestrate workflows
- Interact with external APIs - _autonomously_

Whether you're prototyping an idea, refining existing code, or managing intricate engineering pipelines, goose adapts to your workflow and executes tasks with precision.

[![Watch the video](https://github.com/user-attachments/assets/ddc71240-3928-41b5-8210-626dfb28af7a)](https://youtu.be/D-DpDunrbpo)

## Building from Source

See [WINDOWS.md](WINDOWS.md) for detailed build instructions.

### Quick Build

```powershell
# Clone the repository
git clone https://github.com/dustin-olenslager/goose-windows.git
cd goose-windows

# Build everything
.\scripts\windows\build-windows.ps1 -BuildType release

# Or build and create installer
.\scripts\windows\build-windows.ps1 -BuildType release -Package
```

### Prerequisites

- Windows 10/11 (64-bit)
- Visual Studio Build Tools 2022 (C++ workload)
- Rust (stable, MSVC toolchain)
- Node.js 22+

## Staying in Sync

This fork automatically syncs with upstream [block/goose](https://github.com/block/goose):

- **Automatic sync**: Every 4 hours via GitHub Actions
- **Automatic PRs**: Created when conflicts need manual resolution
- **Manual sync**: Actions → Sync Upstream → Run workflow

## Documentation

- **Upstream Docs**: https://block.github.io/goose/
- **Quickstart**: https://block.github.io/goose/docs/quickstart
- **Tutorials**: https://block.github.io/goose/docs/category/tutorials

## Community

- [Discord](https://discord.gg/goose-oss)
- [YouTube](https://www.youtube.com/@goose-oss)
- [Twitter/X](https://x.com/goose_oss)

## License

Apache-2.0 - Same as the upstream Goose project.

## Links

- **Upstream Repository**: https://github.com/block/goose
- **Windows Fork Issues**: https://github.com/dustin-olenslager/goose-windows/issues
