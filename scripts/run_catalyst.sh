#!/usr/bin/env bash
set -euo pipefail

# Mac Catalyst Build and Run Script
# Builds and runs iOS apps using Mac Catalyst (iOS apps running natively on macOS)
# This is useful for testing iOS apps without a simulator or physical device

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[catalyst]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[catalyst]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[catalyst]${NC} $1"
}

log_error() {
    echo -e "${RED}[catalyst]${NC} $1"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "Mac Catalyst requires macOS"
        exit 1
    fi

    # Check macOS version (Catalina 10.15+ required for Catalyst)
    local macos_version
    macos_version=$(sw_vers -productVersion)
    local major_version
    major_version=$(echo "$macos_version" | cut -d. -f1)

    if [[ "$major_version" -lt 10 ]]; then
        log_error "Mac Catalyst requires macOS 10.15 (Catalina) or later"
        log_error "Current version: $macos_version"
        exit 1
    fi
}

# Check if project supports Mac Catalyst
check_catalyst_support() {
    local project_file="$1"

    if [[ -f "$project_file" ]]; then
        if grep -q "SUPPORTS_MACCATALYST\|Mac Catalyst" "$project_file" 2>/dev/null; then
            return 0
        fi
    fi

    log_warning "Project may not have Mac Catalyst support enabled"
    log_info "To enable: In Xcode, select target > General > Deployment Info > Mac (Catalyst)"
    return 0  # Continue anyway, let xcodebuild fail if not supported
}

show_usage() {
    cat << EOF
Mac Catalyst Build and Run Script

Usage: $0 [OPTIONS] <scheme_name>

Arguments:
    scheme_name     The Xcode scheme to build and run

Options:
    -h, --help              Show this help message
    -n, --no-build          Skip building the app (use existing build)
    -p, --project FILE      Specify the .xcodeproj or .xcworkspace file
    -c, --configuration     Release or Debug (default: Debug)
    -t, --test              Run tests using Mac Catalyst
    -b, --build-only        Build only, don't launch
    --list-schemes          List available schemes

Examples:
    $0 MyApp                        # Build and run MyApp
    $0 --no-build MyApp             # Run existing build
    $0 --test MyApp                 # Run tests via Catalyst
    $0 --configuration Release MyApp # Build release version
    $0 --list-schemes               # Show available schemes

Mac Catalyst Benefits:
    - No simulator required
    - Faster build and run cycle
    - Test on native Mac hardware
    - UI tests run directly on macOS
    - Great for CI/CD on Mac runners

EOF
    exit 0
}

# Default values
SCHEME_NAME=""
SKIP_BUILD=false
PROJECT_FILE=""
CONFIGURATION="Debug"
RUN_TESTS=false
BUILD_ONLY=false
LIST_SCHEMES=false

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
        -p|--project)
            PROJECT_FILE="$2"
            shift 2
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        --list-schemes)
            LIST_SCHEMES=true
            shift
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

log "Platform: macOS $(sw_vers -productVersion) ($(uname -m))"

# Find project/workspace file if not specified
find_project_file() {
    if [[ -n "$PROJECT_FILE" ]]; then
        return 0
    fi

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
}

find_project_file

# Determine project type
PROJECT_ARG=""
if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    PROJECT_ARG="-workspace $PROJECT_FILE"
else
    PROJECT_ARG="-project $PROJECT_FILE"
fi

# List schemes if requested
if [[ "$LIST_SCHEMES" == true ]]; then
    log "Available schemes in $PROJECT_FILE:"
    xcodebuild $PROJECT_ARG -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | grep -v "^$" | head -20 || {
        log_error "Could not list schemes"
        exit 1
    }
    exit 0
fi

# Verify scheme is provided
if [[ -z "$SCHEME_NAME" ]]; then
    log_error "Scheme name is required"
    log "Use --list-schemes to see available schemes"
    show_usage
fi

log "Scheme: $SCHEME_NAME"
log "Configuration: $CONFIGURATION"

# Check Catalyst support
check_catalyst_support "$PROJECT_FILE"

# Mac Catalyst destination
CATALYST_DESTINATION="platform=macOS,variant=Mac Catalyst"

# Derived data path
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"

# Run tests if requested
if [[ "$RUN_TESTS" == true ]]; then
    log "Running tests via Mac Catalyst..."

    xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "$CATALYST_DESTINATION" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME-Catalyst" \
        test 2>&1 | xcbeautify 2>/dev/null || xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "$CATALYST_DESTINATION" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME-Catalyst" \
        test

    log_success "Tests completed!"
    exit 0
fi

# Build the app
if [[ "$SKIP_BUILD" == false ]]; then
    log "Building $SCHEME_NAME for Mac Catalyst..."

    xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "$CATALYST_DESTINATION" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME-Catalyst" \
        build 2>&1 | xcbeautify 2>/dev/null || xcodebuild \
        $PROJECT_ARG \
        -scheme "$SCHEME_NAME" \
        -configuration "$CONFIGURATION" \
        -destination "$CATALYST_DESTINATION" \
        -derivedDataPath "$DERIVED_DATA/$SCHEME_NAME-Catalyst" \
        build

    log_success "Build completed"
else
    log "Skipping build (using existing build)"
fi

# Exit if build only
if [[ "$BUILD_ONLY" == true ]]; then
    log_success "Build complete (--build-only specified)"
    exit 0
fi

# Find the built app
APP_PATH=$(find "$DERIVED_DATA/$SCHEME_NAME-Catalyst" -name "*.app" -path "*/$CONFIGURATION-maccatalyst/*" 2>/dev/null | head -n1)

if [[ -z "$APP_PATH" ]]; then
    # Try alternative search patterns
    APP_PATH=$(find "$DERIVED_DATA" -name "$SCHEME_NAME.app" -path "*/$CONFIGURATION-maccatalyst/*" 2>/dev/null | head -n1)
fi

if [[ -z "$APP_PATH" ]]; then
    # Try without specific configuration
    APP_PATH=$(find "$DERIVED_DATA/$SCHEME_NAME-Catalyst" -name "*.app" -path "*maccatalyst*" 2>/dev/null | head -n1)
fi

if [[ -z "$APP_PATH" ]]; then
    log_error "Could not find built Mac Catalyst app"
    log "Expected location: $DERIVED_DATA/$SCHEME_NAME-Catalyst/Build/Products/$CONFIGURATION-maccatalyst/"
    log ""
    log "Possible issues:"
    log "  1. Mac Catalyst is not enabled for this target"
    log "  2. Build failed silently"
    log "  3. App bundle has a different name than scheme"
    exit 1
fi

log "Found app: $APP_PATH"

# Get bundle ID
BUNDLE_ID=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || echo "")

if [[ -z "$BUNDLE_ID" ]]; then
    log_warning "Could not determine bundle ID, launching by path"
    open "$APP_PATH"
else
    log "Bundle ID: $BUNDLE_ID"

    # Kill existing instance if running
    pkill -f "$BUNDLE_ID" 2>/dev/null || true
    sleep 1

    # Launch the app
    log "Launching app..."
    open "$APP_PATH"
fi

log_success "Done! App is running via Mac Catalyst."
log ""
log "Tips:"
log "  - App runs natively on macOS with iPad interface"
log "  - Window can be resized (behaves like iPad)"
log "  - Menu bar shows iOS-style menus"
log "  - Use Cmd+Q to quit the app"
