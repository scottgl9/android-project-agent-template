# Mobile App Project Template

Project template for AI agents to quickly start building Android and iOS mobile applications.

## Platform Support

| Development Host | Android | iOS | Mac Catalyst |
|-----------------|---------|-----|--------------|
| macOS (Intel/ARM) | ✅ | ✅ | ✅ |
| Linux (x86_64/ARM64) | ✅ | ❌ | ❌ |

> **Note**: iOS development requires macOS due to Xcode requirements. Mac Catalyst allows running iOS apps natively on macOS for testing.

## Quick Start

### 1. Validate Environment

```bash
# Android (macOS or Linux)
./scripts/validate-android-environment.sh

# iOS (macOS only)
./scripts/validate-ios-environment.sh
```

### 2. Install Development Environment

```bash
# Android (macOS or Linux)
./scripts/install-android-environment.sh

# iOS (macOS only)
./scripts/install-ios-environment.sh
```

### 3. Check Connected Devices

```bash
# Android
adb devices

# iOS (simulators)
xcrun simctl list devices
```

### 4. Run Your App

```bash
# Android - run on emulator
./scripts/run_emulator.sh com.example.myapp

# iOS - run on simulator (macOS only)
./scripts/run_simulator.sh MyAppScheme

# iOS - run via Mac Catalyst (macOS only, no simulator needed)
./scripts/run_catalyst.sh MyAppScheme
```

## Project Structure

```
project/
├── android/              # Android app (when using cross-platform)
│   ├── app/
│   └── build.gradle.kts
├── ios/                  # iOS app (macOS only)
│   ├── MyApp.xcodeproj/
│   └── MyApp/
├── scripts/              # Build and automation scripts
│   ├── install-android-environment.sh
│   ├── install-ios-environment.sh
│   ├── validate-android-environment.sh
│   ├── validate-ios-environment.sh
│   ├── run_emulator.sh
│   └── run_simulator.sh
├── AGENTS.md             # Guide for AI agents
├── CLAUDE.md             # Guide for Claude
├── CODEX.md              # Guide for GitHub Copilot/Codex
├── PLATFORM_GUIDE.md     # Cross-platform development guide
├── PRD.md                # Product Requirements Document
├── TODO.md               # Task tracking
├── PROGRESS.md           # Development progress log
└── README.md             # This file
```

## For AI Agents

Choose the appropriate guide based on your agent type:

- **Claude Code / Claude AI** → Use `CLAUDE.md`
- **GitHub Copilot / Codex** → Use `CODEX.md`
- **Other AI Agents** → Use `AGENTS.md`

For cross-platform development details, see `PLATFORM_GUIDE.md`.

## Android Development

### Requirements
- JDK 21
- Android SDK (platforms 34-35, build-tools 34+)
- Gradle 8.10+

### Common Commands
```bash
./gradlew build              # Build project
./gradlew test               # Run unit tests
./gradlew installDebug       # Install on device
./gradlew connectedAndroidTest  # Run instrumented tests
```

## iOS Development (macOS Only)

### Requirements
- macOS 12.0+
- Xcode (from Mac App Store)
- CocoaPods, SwiftLint, SwiftFormat (installed via script)

### Common Commands
```bash
xcodebuild -scheme MyApp build    # Build project
xcodebuild test -scheme MyApp     # Run tests
pod install                       # Install dependencies
```

### Mac Catalyst (iOS on Mac)

Run iOS apps natively on macOS without a simulator:
```bash
# Build and run via Mac Catalyst
./scripts/run_catalyst.sh MyAppScheme

# Run tests via Catalyst
./scripts/run_catalyst.sh --test MyAppScheme

# Run UI tests via Catalyst
./scripts/run-ui-tests.sh catalyst
```

Benefits: Faster builds, no simulator overhead, ideal for CI/CD.

## Documentation

- `PLATFORM_GUIDE.md` - Detailed cross-platform development guide
- `ARCHITECTURE.md` - System architecture documentation
- `PRD.md` - Product requirements document
- `TODO.md` - Current task list
- `PROGRESS.md` - Development progress log
- `BUGS.md` - Bug tracking

## Scripts Reference

| Script | Platform | Description |
|--------|----------|-------------|
| `install-android-environment.sh` | macOS, Linux | Install Android SDK and tools |
| `validate-android-environment.sh` | macOS, Linux | Verify Android environment |
| `run_emulator.sh` | macOS, Linux | Build, install, and run on emulator |
| `install-ios-environment.sh` | macOS only | Install iOS development tools |
| `validate-ios-environment.sh` | macOS only | Verify iOS environment |
| `run_simulator.sh` | macOS only | Build, install, and run on simulator |
| `run_catalyst.sh` | macOS only | Build and run via Mac Catalyst |
| `install-ui-testing.sh` | macOS, Linux | Install Maestro UI testing |
| `run-ui-tests.sh` | macOS, Linux | Run UI tests (android, ios, catalyst) |
| `autonomous-dev.sh` | macOS, Linux | Run autonomous development mode |
| `orchestrate.sh` | macOS, Linux | Generate development status report |

## Getting Started

1. Clone this template
2. Run the appropriate validation script for your platform
3. Install the development environment if needed
4. Create your `PRD.md` with product requirements
5. Start development following the agent guides

## License

[Your License Here]
