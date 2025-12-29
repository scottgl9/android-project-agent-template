#!/usr/bin/env bash
set -euo pipefail

# Android Emulator Launch Script
# Supports both macOS and Linux platforms
# This script builds the app, starts an emulator, installs, and launches the app

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[run_emulator]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[run_emulator]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[run_emulator]${NC} $1"
}

log_error() {
    echo -e "${RED}[run_emulator]${NC} $1"
}

# Detect OS
detect_os() {
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [[ "$os" == "darwin" ]]; then
        echo "macos"
    elif [[ "$os" == "linux" ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Detect architecture
detect_arch() {
    uname -m
}

# Setup environment based on OS
setup_environment() {
    local os
    os=$(detect_os)

    # Set ANDROID_HOME if not already set
    if [[ -z "${ANDROID_HOME:-}" ]]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    fi

    # Add Android tools to PATH
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

    # Set JAVA_HOME based on OS if not already set
    if [[ -z "${JAVA_HOME:-}" ]]; then
        if [[ "$os" == "macos" ]]; then
            if command -v /usr/libexec/java_home >/dev/null 2>&1; then
                export JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || echo "")
            fi
        else
            # Linux - try common paths
            for path in "/usr/lib/jvm/java-21-openjdk-amd64" "/usr/lib/jvm/java-21-openjdk" "/usr/lib/jvm/jdk-21"; do
                if [[ -d "$path" ]]; then
                    export JAVA_HOME="$path"
                    break
                fi
            done
        fi
    fi

    if [[ -n "${JAVA_HOME:-}" ]]; then
        export PATH="$JAVA_HOME/bin:$PATH"
    fi
}

show_usage() {
    cat << EOF
Android Emulator Launch Script

Usage: $0 [OPTIONS] <package_name> [main_activity]

Arguments:
    package_name    The application package name (e.g., com.example.myapp)
    main_activity   The main activity to launch (default: .MainActivity)

Options:
    -h, --help      Show this help message
    -n, --no-build  Skip building the APK (use existing build)
    -a, --avd NAME  Use a specific AVD (default: test_avd)

Examples:
    $0 com.example.myapp
    $0 com.example.myapp .ui.MainActivity
    $0 --no-build com.mycompany.app
    $0 --avd Pixel_4_API_34 com.example.myapp

Supported Platforms:
    - macOS (Intel and Apple Silicon)
    - Linux (x86_64 and ARM64)

EOF
    exit 0
}

# Default values
AVD_NAME="test_avd"
APP_PACKAGE=""
MAIN_ACTIVITY=".MainActivity"
SKIP_BUILD=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        -n|--no-build)
            SKIP_BUILD=true
            shift
            ;;
        -a|--avd)
            AVD_NAME="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            ;;
        *)
            if [[ -z "$APP_PACKAGE" ]]; then
                APP_PACKAGE="$1"
            else
                MAIN_ACTIVITY="$1"
            fi
            shift
            ;;
    esac
done

# Setup environment
setup_environment

# Determine paths
EMULATOR_BIN="$ANDROID_HOME/emulator/emulator"
ADB_BIN="adb"

log "Platform: $(detect_os) ($(detect_arch))"
log "ANDROID_HOME: $ANDROID_HOME"
log "JAVA_HOME: ${JAVA_HOME:-not set}"

# Check if package name is provided
if [[ -z "$APP_PACKAGE" ]]; then
    log_error "Application package name is required"
    show_usage
fi

# Verify Java installation
if [[ -n "${JAVA_HOME:-}" ]] && [[ -f "$JAVA_HOME/bin/java" ]]; then
    log "Using Java from: $JAVA_HOME"
    "$JAVA_HOME/bin/java" -version 2>&1 | head -n1
elif command -v java >/dev/null 2>&1; then
    log "Using Java from PATH"
    java -version 2>&1 | head -n1
else
    log_error "Java not found. Please install JDK 21."
    exit 1
fi

# Verify emulator exists
if [[ ! -f "$EMULATOR_BIN" ]]; then
    log_error "Emulator not found at $EMULATOR_BIN"
    log "Please run ./scripts/install-android-environment.sh first"
    exit 1
fi

# Verify adb exists
if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
    log_error "adb not found in PATH"
    log "Please ensure Android SDK platform-tools are installed"
    exit 1
fi

log "Resetting adb server"
$ADB_BIN kill-server >/dev/null 2>&1 || true
$ADB_BIN start-server >/dev/null 2>&1 || true

log "Checking for running emulators"
$ADB_BIN devices | awk '/^emulator-/{print $1}' | while read -r device; do
    log_warning "Stopping existing emulator: $device"
    $ADB_BIN -s "$device" emu kill 2>/dev/null || true
    sleep 1
done

# Build the APK if not skipped
APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
if [[ "$SKIP_BUILD" == false ]]; then
    log "Building debug APK"
    ./gradlew :app:assembleDebug
else
    log "Skipping build (using existing APK)"
fi

if [[ ! -f "$APK_PATH" ]]; then
    log_error "APK not found at $APK_PATH"
    log "Please build the project first: ./gradlew :app:assembleDebug"
    exit 1
fi

# Check if AVD exists
if ! "$EMULATOR_BIN" -list-avds 2>/dev/null | grep -q "^$AVD_NAME$"; then
    log_error "AVD '$AVD_NAME' not found"
    log "Available AVDs:"
    "$EMULATOR_BIN" -list-avds 2>/dev/null || echo "  None found"
    log "Create one with: ./scripts/install-android-environment.sh"
    exit 1
fi

# Determine GPU option based on platform
GPU_OPTION="swiftshader_indirect"
if [[ "$(detect_os)" == "macos" ]]; then
    # macOS typically works better with host GPU
    GPU_OPTION="host"
fi

log "Starting emulator: $AVD_NAME (GPU: $GPU_OPTION)"
nohup "$EMULATOR_BIN" -avd "$AVD_NAME" -gpu "$GPU_OPTION" -no-boot-anim >/tmp/emulator.log 2>&1 &

log "Waiting for device to come online"
$ADB_BIN wait-for-device

log "Waiting for boot completion"
until $ADB_BIN shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; do
    sleep 2
done

# Unlock screen
$ADB_BIN shell input keyevent 82 >/dev/null 2>&1 || true

log "Installing APK: $APK_PATH"
$ADB_BIN install -r "$APK_PATH"

log "Launching app: $APP_PACKAGE/$MAIN_ACTIVITY"
$ADB_BIN shell am start -n "$APP_PACKAGE/$MAIN_ACTIVITY"

log_success "Done! App is running on emulator."
