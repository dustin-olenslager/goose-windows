# Goose for Windows

This is a Windows-optimized fork of [Block's Goose](https://github.com/block/goose) AI agent, designed for the best native Windows experience.

## Features

- **Native Windows 11 Title Bar**: Proper minimize, maximize, and close controls
- **One-Click Auto-Updates**: Seamless updates via Settings → App → Check for Updates
- **Native MSVC Builds**: Uses Microsoft Visual C++ toolchain for optimal Windows performance
- **Windows Installer**: Squirrel-based installer with automatic updates
- **Claude CLI Provider Fix**: Works correctly with Windows subprocess handling
- **Automatic Sync**: Stays up-to-date with upstream block/goose every 4 hours
- **PowerShell Scripts**: Easy-to-use build and development scripts

## Quick Start

### Download

**[Download Latest Release](https://github.com/dustin-olenslager/goose-windows/releases/latest)**

- **Goose-X.X.X.Setup.exe** - Windows installer with auto-updates (recommended)
- **Goose-win32-x64-X.X.X.zip** - Portable version

### Install

1. Download `Goose-X.X.X.Setup.exe` from the latest release
2. Run the installer
3. Goose installs to `%LOCALAPPDATA%\Goose`
4. Launch from Start Menu

### Updating

The app automatically checks for updates. To manually update:

1. Open Goose
2. Go to **Settings** (sidebar) → **App** tab
3. Click **Check for Updates**
4. Click **Install & Restart** when available

## Building from Source

### Prerequisites

- **Windows 10/11** (64-bit)
- **Visual Studio Build Tools 2022** or Visual Studio 2022
  - Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
  - Select "Desktop development with C++" workload
- **Rust** (stable, MSVC toolchain)
  - Install from: https://rustup.rs
- **Node.js 22+**
  - Download from: https://nodejs.org

### Automated Setup

Run the setup script to install all prerequisites:

```powershell
# Run as Administrator for full setup
.\scripts\windows\setup-dev-env.ps1 -All
```

### Manual Build

```powershell
# Clone the repository
git clone https://github.com/dustin-olenslager/goose-windows.git
cd goose-windows

# Build everything (Rust + Electron UI)
.\scripts\windows\build-windows.ps1 -BuildType release

# Or build and create installer
.\scripts\windows\build-windows.ps1 -BuildType release -Package
```

### Build Options

```powershell
# Debug build (faster compilation, larger binaries)
.\scripts\windows\build-windows.ps1 -BuildType debug

# Release build (optimized)
.\scripts\windows\build-windows.ps1 -BuildType release

# Skip Rust compilation (UI only)
.\scripts\windows\build-windows.ps1 -SkipRust

# Skip UI build (Rust only)
.\scripts\windows\build-windows.ps1 -SkipUI

# Clean build (removes all artifacts first)
.\scripts\windows\build-windows.ps1 -CleanBuild

# Create distributable package
.\scripts\windows\build-windows.ps1 -Package

# Sign executables (requires certificate)
.\scripts\windows\build-windows.ps1 -Package -Sign
```

### Development

For day-to-day development:

```powershell
# Quick build and run
.\scripts\windows\dev-run.ps1

# Or manually:
cargo build
cd ui\desktop
npm install
npm run start-gui
```

## Architecture

```
goose-windows/
├── crates/                 # Rust workspace
│   ├── goose/             # Core AI agent
│   ├── goose-server/      # Backend server (goosed.exe)
│   ├── goose-cli/         # CLI tool (goose.exe)
│   └── goose-mcp/         # MCP protocol
├── ui/desktop/            # Electron app
│   ├── src/
│   │   ├── main.ts        # Main process
│   │   ├── platform/
│   │   │   └── windows/   # Windows-specific code
│   │   └── bin/           # Bundled binaries
│   └── forge.config.ts    # Electron Forge config
├── scripts/windows/       # Windows build scripts
│   ├── build-windows.ps1  # Main build script
│   ├── setup-dev-env.ps1  # Development setup
│   └── dev-run.ps1        # Quick dev runner
├── .cargo/config.toml     # Cargo configuration
└── .github/workflows/     # CI/CD pipelines
    ├── windows-build.yml  # Windows CI
    └── sync-upstream.yml  # Upstream sync
```

## Staying Updated

This fork automatically syncs with the upstream [block/goose](https://github.com/block/goose) repository:

- **Automatic sync**: Runs every 4 hours
- **Automatic PRs**: Creates PRs when conflicts need manual resolution
- **Manual sync**: Trigger via Actions → Sync Upstream → Run workflow

### Manual Sync

```powershell
# Add upstream remote
git remote add upstream https://github.com/block/goose.git

# Fetch and merge
git fetch upstream
git merge upstream/main

# Push to your fork
git push origin main
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `WINDOWS_CERTIFICATE_FILE` | Path to code signing certificate |
| `WINDOWS_CERTIFICATE_PASSWORD` | Certificate password |
| `GITHUB_REPOSITORY_OWNER` | GitHub owner for releases |
| `GITHUB_REPOSITORY_NAME` | GitHub repo name for releases |

### Code Signing

To sign releases:

1. Obtain a code signing certificate
2. Set environment variables:
   ```powershell
   $env:WINDOWS_CERTIFICATE_FILE = "path\to\cert.pfx"
   $env:WINDOWS_CERTIFICATE_PASSWORD = "your-password"
   ```
3. Build with signing:
   ```powershell
   .\scripts\windows\build-windows.ps1 -Package -Sign
   ```

## Troubleshooting

### Build Errors

**"LINK : fatal error LNK1181: cannot open input file"**
- Install Visual Studio Build Tools with C++ workload

**"error: linker `link.exe` not found"**
- Run from "Developer Command Prompt for VS 2022"
- Or install MSVC target: `rustup target add x86_64-pc-windows-msvc`

**"npm ERR! code ENOENT"**
- Run `npm ci` in `ui/desktop` directory
- Check Node.js version: `node --version` (should be 22+)

### Runtime Issues

**"goosed.exe failed to start"**
- Check Windows Defender isn't blocking the executable
- Ensure port 3000+ is available
- Check logs at `%LOCALAPPDATA%\Goose\logs`

**"Protocol handler not working"**
- Reinstall the application
- Manually register: `.\Goose.exe --register-protocol`

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

Please ensure your changes work on Windows before submitting.

## License

Apache-2.0 - Same as the upstream Goose project.

## Links

- **Upstream**: https://github.com/block/goose
- **Documentation**: https://block.github.io/goose/
- **Issues**: https://github.com/dustin-olenslager/goose-windows/issues
