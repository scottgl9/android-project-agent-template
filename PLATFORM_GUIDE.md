# Cross-Platform Development Guide

This guide covers developing mobile applications for both Android and iOS platforms, with support for macOS and Linux development environments.

## Platform Support Matrix

| Development Host | Android Development | iOS Development | Mac Catalyst |
|-----------------|---------------------|-----------------|--------------|
| macOS (Intel)   | ✅ Full support     | ✅ Full support | ✅ Full support |
| macOS (Apple Silicon) | ✅ Full support | ✅ Full support | ✅ Full support |
| Linux (x86_64)  | ✅ Full support     | ❌ Not supported | ❌ Not supported |
| Linux (ARM64)   | ✅ Full support     | ❌ Not supported | ❌ Not supported |
| Windows         | ⚠️ Via WSL2        | ❌ Not supported | ❌ Not supported |

> **Note**: iOS development requires macOS due to Xcode requirements. Android development works on both macOS and Linux. Mac Catalyst allows running iOS apps natively on macOS.

## Quick Start

### Environment Setup

```bash
# Validate your current environment
./scripts/validate-android-environment.sh
./scripts/validate-ios-environment.sh  # macOS only

# Install Android environment (macOS or Linux)
./scripts/install-android-environment.sh

# Install iOS environment (macOS only)
./scripts/install-ios-environment.sh
```

### Running Apps

```bash
# Android - Run on emulator
./scripts/run_emulator.sh com.example.myapp

# iOS - Run on simulator (macOS only)
./scripts/run_simulator.sh MyAppScheme
```

## Android Development

### Supported Platforms

- **macOS**: Intel (x86_64) and Apple Silicon (ARM64)
- **Linux**: Ubuntu, Debian, Fedora, CentOS, RHEL, Arch

### Requirements

- JDK 21 (OpenJDK recommended)
- Android SDK with:
  - Platform Tools
  - Build Tools 34.0.0+
  - Android 34/35 platforms
- Gradle 8.10+

### Installation

```bash
# Full installation
./scripts/install-android-environment.sh

# Verify installation
./scripts/validate-android-environment.sh

# Force reinstall
./scripts/install-android-environment.sh --force
```

### Project Structure

```
project/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/package/
│   │   │   ├── res/
│   │   │   └── AndroidManifest.xml
│   │   ├── test/           # Unit tests
│   │   └── androidTest/    # Instrumented tests
│   └── build.gradle.kts
├── build.gradle.kts
├── settings.gradle.kts
└── gradle/
    └── wrapper/
```

### Common Commands

```bash
# Build debug APK
./gradlew :app:assembleDebug

# Build release APK
./gradlew :app:assembleRelease

# Run unit tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest

# Lint check
./gradlew lint

# Clean build
./gradlew clean build

# Install on connected device
./gradlew installDebug

# Check connected devices
adb devices
```

### Testing on Devices

#### Real Device (Preferred)
```bash
# Check device connection
adb devices

# Install APK
adb install app/build/outputs/apk/debug/app-debug.apk

# View logs
adb logcat | grep "YourAppTag"

# Clear app data
adb shell pm clear com.your.package
```

#### Emulator
```bash
# List available AVDs
emulator -list-avds

# Start emulator
./scripts/run_emulator.sh com.example.myapp

# Or start manually
emulator -avd test_avd
```

## iOS Development

### Requirements (macOS Only)

- macOS 12.0 or later
- Xcode (from Mac App Store)
- Xcode Command Line Tools
- CocoaPods (for dependency management)
- Swift 5.9+

### Installation

```bash
# Full installation (requires macOS)
./scripts/install-ios-environment.sh

# Minimal installation
./scripts/install-ios-environment.sh --minimal

# Full installation with fastlane
./scripts/install-ios-environment.sh --full

# Verify installation
./scripts/validate-ios-environment.sh
```

### Project Structure

```
project/
├── ios/
│   ├── MyApp.xcodeproj/
│   │   └── project.pbxproj
│   ├── MyApp/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── ContentView.swift
│   │   ├── Assets.xcassets/
│   │   └── Info.plist
│   ├── MyAppTests/
│   └── MyAppUITests/
└── Podfile (if using CocoaPods)
```

### Common Commands

```bash
# Build for simulator
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -scheme MyApp -destination 'generic/platform=iOS' build

# Run tests
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for distribution
xcodebuild archive -scheme MyApp -archivePath build/MyApp.xcarchive

# Clean build folder
xcodebuild clean -scheme MyApp

# Install CocoaPods dependencies
pod install
```

### Testing on Devices

#### Simulator
```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15"

# Install app on simulator
xcrun simctl install booted /path/to/MyApp.app

# Launch app
xcrun simctl launch booted com.example.MyApp

# Open Simulator app
open -a Simulator

# Take screenshot
xcrun simctl io booted screenshot screenshot.png
```

#### Real Device
```bash
# List connected devices
xcrun xctrace list devices

# Build and run on device (requires code signing)
xcodebuild -scheme MyApp -destination 'platform=iOS,id=DEVICE_ID' build
```

## Mac Catalyst Development

Mac Catalyst allows iOS apps to run natively on macOS. This is useful for:
- **Testing without simulators**: Faster build and run cycle
- **CI/CD on Mac runners**: No simulator setup required
- **Development on Mac**: Debug iOS UI directly on your Mac

### Requirements

- macOS 10.15 (Catalina) or later
- Xcode 11+
- Project must have Mac Catalyst support enabled

### Enabling Mac Catalyst in Your Project

1. Open your Xcode project
2. Select your app target
3. Go to **General** > **Deployment Info**
4. Check **Mac** (under "Designed for iPad")
5. Build and run

### Building and Running

```bash
# Build for Mac Catalyst
./scripts/run_catalyst.sh MyAppScheme

# Build only (don't launch)
./scripts/run_catalyst.sh --build-only MyAppScheme

# Run tests via Mac Catalyst
./scripts/run_catalyst.sh --test MyAppScheme

# Build release version
./scripts/run_catalyst.sh --configuration Release MyAppScheme

# List available schemes
./scripts/run_catalyst.sh --list-schemes
```

### Manual xcodebuild Commands

```bash
# Build for Mac Catalyst
xcodebuild -scheme MyApp \
    -destination 'platform=macOS,variant=Mac Catalyst' \
    build

# Run tests via Mac Catalyst
xcodebuild test -scheme MyApp \
    -destination 'platform=macOS,variant=Mac Catalyst'

# Archive for distribution
xcodebuild archive -scheme MyApp \
    -destination 'platform=macOS,variant=Mac Catalyst' \
    -archivePath build/MyApp-Catalyst.xcarchive
```

### UI Testing with Mac Catalyst

```bash
# Run UI tests on Mac Catalyst
./scripts/run-ui-tests.sh catalyst

# Run specific test
./scripts/run-ui-tests.sh -t login_flow.yaml catalyst
```

### Mac Catalyst vs iOS Simulator

| Feature | Mac Catalyst | iOS Simulator |
|---------|--------------|---------------|
| Speed | ⚡ Faster | 🐢 Slower |
| Hardware Access | Native Mac | Simulated iOS |
| UI Appearance | iPad (resizable) | iPhone/iPad |
| CI/CD | ✅ Simple | Requires setup |
| Debugging | Full support | Full support |
| Screenshots | Native macOS | Simulated |

### Troubleshooting

**"Mac Catalyst not supported"**
- Enable Mac Catalyst in Xcode project settings
- Check minimum deployment target (iOS 13+)

**Build fails for Catalyst**
- Some iOS-only frameworks don't support Catalyst
- Check for `#if targetEnvironment(macCatalyst)` conditionals

**App doesn't look right**
- Catalyst uses iPad UI scaled to Mac
- Consider adding Mac-specific UI adjustments

## Cross-Platform Strategies

### Shared Code Approaches

1. **Kotlin Multiplatform (KMP)**
   - Share business logic between Android and iOS
   - Native UI for each platform
   - Gradual adoption possible

2. **React Native / Flutter**
   - Single codebase for both platforms
   - Near-native performance
   - Large ecosystem

3. **Native with Shared Backend**
   - Separate native codebases
   - Shared API/Backend
   - Best native experience

### Recommended Architecture

```
project/
├── android/              # Android app
│   ├── app/
│   └── build.gradle.kts
├── ios/                  # iOS app
│   ├── MyApp.xcodeproj/
│   └── MyApp/
├── shared/               # Shared code (if using KMP)
│   ├── src/
│   │   ├── commonMain/
│   │   ├── androidMain/
│   │   └── iosMain/
│   └── build.gradle.kts
├── scripts/              # Build and automation scripts
└── docs/                 # Documentation
```

## Environment Variables

### Android

```bash
# Required
export JAVA_HOME="/path/to/jdk"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"

# PATH additions
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/emulator"
```

### iOS (macOS)

```bash
# Usually automatic via Xcode
# Verify with:
xcode-select -p

# Set developer directory if needed:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Troubleshooting

### Android Issues

**Device not detected:**
```bash
# Restart ADB
adb kill-server && adb start-server

# Check USB debugging is enabled on device
# Try different USB mode (File Transfer/PTP)
```

**Build fails with Java errors:**
```bash
# Verify JAVA_HOME
echo $JAVA_HOME
java -version

# Should be JDK 21
```

**Emulator won't start:**
```bash
# Check available AVDs
emulator -list-avds

# Run with verbose logging
emulator -avd test_avd -verbose

# On ARM Mac, ensure arm64-v8a system image is installed
```

### iOS Issues

**Xcode not found:**
```bash
# Install from Mac App Store
# Then accept license:
sudo xcodebuild -license accept

# Set developer directory:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Simulator not available:**
```bash
# Download iOS runtime:
xcodebuild -downloadPlatform iOS

# Or via Xcode: Settings > Platforms > +
```

**Code signing issues:**
```bash
# List available signing identities
security find-identity -v -p codesigning

# For development, use automatic signing in Xcode
```

## CI/CD Considerations

### GitHub Actions

```yaml
# Android on Ubuntu
jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
      - run: ./gradlew build

# iOS on macOS
  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild -scheme MyApp build
```

### Local CI Testing

```bash
# Android
./gradlew clean build test lint

# iOS
xcodebuild clean build test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Best Practices

1. **Environment Validation**: Always run validation scripts before development
2. **Version Control**: Include gradle wrapper and project settings
3. **Dependency Management**: Use version catalogs (Android) and Podfile.lock (iOS)
4. **Testing**: Write tests that can run on CI without physical devices
5. **Documentation**: Keep platform-specific README in each subdirectory
6. **Scripts**: Use the provided scripts for consistent builds across team members
