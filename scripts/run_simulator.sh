#!/usr/bin/env bash
set -euo pipefail

# iOS Simulator Launch Script
# This script builds the app, starts a simulator, installs, and launches the app
# Note: This script only works on macOS

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[run_simulator]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[run_simulator]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[run_simulator]${NC} $1"
}

log_error() {
    echo -e "${RED}[run_simulator]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "This script requires macOS"
        exit 1
    fi
}

show_usage() {
    cat << EOF
iOS Simulator Launch Script

Usage: $0 [OPTIONS] <scheme_name>

Arguments:
    scheme_name     The Xcode scheme to build and run

Options:
    -h, --help          Show this help message
    -n, --no-build      Skip building the app (use existing build)
    -d, --device NAME   Use a specific simulator device (default: iPhone 15)
    -p, --project FILE  Specify the .xcodeproj or .xcworkspace file
    -c, --configuration Release or Debug (default: Debug)

Examples:
    $0 MyApp
    $0 --no-build MyApp
    $0 --device "iPhone 15 Pro" MyApp
    $0 --project MyApp.xcworkspace MyApp
    $0 --configuration Release MyApp

EOF
    exit 0
}

# Default values
SCHEME_NAME=""
DEVICE_NAME="iPhone 15"
SKIP_BUILD=false
PROJECT_FILE=""
CONFIGURATION="Debug"

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
        -d|--device)
            DEVICE_NAME="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_FILE="$2"
            shift 2
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            ;;
        *)
            SCHEME_NAME="$1"
            shift
            ;;
    esac
done

# Check macOS
check_macos

# Verify scheme is provided
if [[ -z "$SCHEME_NAME" ]]; then
    log_error "Scheme name is required"
    show_usage
fi

log "Platform: macOS $(sw_vers -productVersion) ($(uname -m))"
log "Scheme: $SCHEME_NAME"
log "Device: $DEVICE_NAME"
log "Configuration: $CONFIGURATION"

# Find project/workspace file if not specified
if [[ -z "$PROJECT_FILE" ]]; then
    if ls *.xcworkspace 1>/dev/null 2>&1; then
        PROJECT_FILE=$(ls *.xcworkspace | head -n1)
        log "Found workspace: $PROJECT_FILE"
    elif ls *.xcodeproj 1>/dev/null 2>&1; then
        PROJECT_FILE=$(ls *.xcodeproj | head -n1)
        log "Found project: $PROJECT_FILE"
    else
        # Check in ios/ subdirectory
        if ls ios/*.xcworkspace 1>/dev/null 2>&1; then
            PROJECT_FILE=$(ls ios/*.xcworkspace | head -n1)
            log "Found workspace: $PROJECT_FILE"
        elif ls ios/*.xcodeproj 1>/dev/null 2>&1; then
            PROJECT_FILE=$(ls ios/*.xcodeproj | head -n1)
            log "Found project: $PROJECT_FILE"
        else
            log_error "No .xcworkspace or .xcodeproj found"
            log "Please specify with --project option"
            exit 1
        fi
    fi
fi

# Determine project type
PROJECT_ARG=""
if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    PROJECT_ARG="-workspace $PROJECT_FILE"
else
    PROJECT_ARG="-project $PROJECT_FILE"
fi

# Find or create simulator
log "Looking for simulator: $DEVICE_NAME"
SIMULATOR_ID=$(xcrun simctl list devices available | grep "$DEVICE_NAME" | grep -v "unavailable" | head -n1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || echo "")

if [[ -z "$SIMULATOR_ID" ]]; then
    log_warning "Simulator '$DEVICE_NAME' not found"
    log "Available simulators:"
    xcrun simctl list devices available | grep "iPhone" | head -10

    # Try to use first available iPhone
    SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -n1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || echo "")

    if [[ -z "$SIMULATOR_ID" ]]; then
        log_error "No iPhone simulators available"
        log "Download simulators from Xcode > Settings > Platforms"
        exit 1
    fi

    DEVICE_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_ID" | sed 's/(.*//' | xargs)
    log "Using simulator: $DEVICE_NAME ($SIMULATOR_ID)"
fi

# Boot simulator if not running
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "(Booted)" || echo "")
if [[ -z "$SIMULATOR_STATE" ]]; then
    log "Booting simulator: $DEVICE_NAME"
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    sleep 2
fi

# Open Simulator app
log "Opening Simulator app"
open -a Simulator

# Wait for simulator to be ready
log "Waiting for simulator to be ready..."
sleep 3

# Build the app
if [[ "$SKIP_BUILD" == false ]]; then
    log "Building $SCHEME_NAME for simulator..."

    # Determine derived data path
    DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

    xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME" \
        build 2>&1 | xcbeautify 2>/dev/null || xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME" \
        build

    log_success "Build completed"
else
    log "Skipping build (using existing build)"
fi

# Find the built app
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA/$SCHEME_NAME" -name "*.app" -path "*/$CONFIGURATION-iphonesimulator/*" 2>/dev/null | head -n1)

if [[ -z "$APP_PATH" ]]; then
    # Try alternative search
    APP_PATH=$(find "$DERIVED_DATA" -name "$SCHEME_NAME.app" -path "*/$CONFIGURATION-iphonesimulator/*" 2>/dev/null | head -n1)
fi

if [[ -z "$APP_PATH" ]]; then
    log_error "Could not find built app"
    log "Expected location: $DERIVED_DATA/$SCHEME_NAME/Build/Products/$CONFIGURATION-iphonesimulator/"
    exit 1
fi

log "Found app: $APP_PATH"

# Install the app
log "Installing app on simulator..."
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

# Get bundle ID
BUNDLE_ID=$(defaults read "$APP_PATH/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")

if [[ -z "$BUNDLE_ID" ]]; then
    log_error "Could not determine bundle ID"
    exit 1
fi

log "Bundle ID: $BUNDLE_ID"

# Launch the app
log "Launching app..."
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

log_success "Done! App is running on simulator."
