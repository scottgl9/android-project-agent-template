#!/bin/bash

# iOS Build and Test Environment Installation Script
# This script sets up a complete iOS development environment on macOS
# Note: iOS development requires macOS - this script will exit on other platforms
# Version: 1.0
# Date: December 2025

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
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

# Function to detect Architecture
detect_arch() {
    uname -m
}

# Function to get macOS version
get_macos_version() {
    sw_vers -productVersion 2>/dev/null || echo "unknown"
}

# Check if running on macOS
check_macos() {
    if [[ "$(detect_os)" != "macos" ]]; then
        log_error "iOS development requires macOS."
        log_info "Current OS: $(uname -s)"
        log_info "Please run this script on a Mac."
        exit 1
    fi
    log_success "Running on macOS $(get_macos_version) ($(detect_arch))"
}

# Function to install Homebrew
install_homebrew() {
    if command_exists brew; then
        log_success "Homebrew is already installed"
        log_info "Updating Homebrew..."
        brew update
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon
        if [[ "$(detect_arch)" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        log_success "Homebrew installed successfully"
    fi
}

# Function to install Xcode Command Line Tools
install_xcode_cli() {
    log_info "Checking Xcode Command Line Tools..."

    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools are already installed"
    else
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true

        # Wait for installation
        log_warning "Please complete the Xcode Command Line Tools installation in the popup window."
        log_info "Press Enter when installation is complete..."
        read -r

        if xcode-select -p &>/dev/null; then
            log_success "Xcode Command Line Tools installed successfully"
        else
            log_error "Xcode Command Line Tools installation failed"
            exit 1
        fi
    fi
}

# Function to check/install Xcode
check_xcode() {
    log_info "Checking Xcode installation..."

    if [[ -d "/Applications/Xcode.app" ]]; then
        local xcode_version
        xcode_version=$(xcodebuild -version 2>/dev/null | head -n1 || echo "Unknown")
        log_success "Xcode is installed: $xcode_version"

        # Accept license if needed
        if ! sudo xcodebuild -license check &>/dev/null; then
            log_info "Accepting Xcode license..."
            sudo xcodebuild -license accept
        fi

        # Select Xcode
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        log_success "Xcode developer directory set"
    else
        log_warning "Xcode is not installed"
        log_info "Please install Xcode from the Mac App Store:"
        log_info "  https://apps.apple.com/app/xcode/id497799835"
        log_info ""
        log_info "After installing Xcode, run this script again."
        log_info ""
        log_info "Alternatively, you can use xcode-select to install command line tools only:"
        log_info "  xcode-select --install"
        exit 1
    fi
}

# Function to install iOS development tools
install_ios_tools() {
    log_info "Installing iOS development tools..."

    # Install CocoaPods
    if command_exists pod; then
        local pod_version
        pod_version=$(pod --version)
        log_success "CocoaPods is already installed (v$pod_version)"
    else
        log_info "Installing CocoaPods..."
        brew install cocoapods
        log_success "CocoaPods installed"
    fi

    # Install SwiftLint
    if command_exists swiftlint; then
        local swiftlint_version
        swiftlint_version=$(swiftlint version)
        log_success "SwiftLint is already installed (v$swiftlint_version)"
    else
        log_info "Installing SwiftLint..."
        brew install swiftlint
        log_success "SwiftLint installed"
    fi

    # Install SwiftFormat
    if command_exists swiftformat; then
        local swiftformat_version
        swiftformat_version=$(swiftformat --version)
        log_success "SwiftFormat is already installed (v$swiftformat_version)"
    else
        log_info "Installing SwiftFormat..."
        brew install swiftformat
        log_success "SwiftFormat installed"
    fi

    # Install xcbeautify for better Xcode output
    if command_exists xcbeautify; then
        log_success "xcbeautify is already installed"
    else
        log_info "Installing xcbeautify..."
        brew install xcbeautify
        log_success "xcbeautify installed"
    fi

    # Install xcpretty as fallback
    if command_exists xcpretty; then
        log_success "xcpretty is already installed"
    else
        log_info "Installing xcpretty..."
        gem install xcpretty --user-install || sudo gem install xcpretty
        log_success "xcpretty installed"
    fi
}

# Function to install iOS simulators
install_simulators() {
    log_info "Checking iOS Simulators..."

    # List available simulators
    local simulators
    simulators=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone" || echo "0")

    if [[ "$simulators" -gt 0 ]]; then
        log_success "Found $simulators available iPhone simulator(s)"
        log_info "Available simulators:"
        xcrun simctl list devices available | grep "iPhone" | head -5
    else
        log_warning "No iPhone simulators found"
        log_info "You can download simulators from Xcode:"
        log_info "  Xcode > Settings > Platforms > +"
        log_info ""
        log_info "Or use the command line:"
        log_info "  xcodebuild -downloadPlatform iOS"
    fi
}

# Function to setup fastlane (optional)
install_fastlane() {
    log_info "Checking fastlane..."

    if command_exists fastlane; then
        local fastlane_version
        fastlane_version=$(fastlane --version | head -n1)
        log_success "fastlane is already installed ($fastlane_version)"
    else
        log_info "Installing fastlane..."
        brew install fastlane
        log_success "fastlane installed"
    fi
}

# Function to verify installation
verify_installation() {
    log_info "Verifying iOS environment installation..."

    local errors=0

    # Check Xcode
    if [[ -d "/Applications/Xcode.app" ]]; then
        log_success "✓ Xcode is installed"
    else
        log_error "✗ Xcode is not installed"
        errors=$((errors + 1))
    fi

    # Check xcodebuild
    if command_exists xcodebuild; then
        local xcode_version
        xcode_version=$(xcodebuild -version 2>/dev/null | head -n1)
        log_success "✓ xcodebuild is available ($xcode_version)"
    else
        log_error "✗ xcodebuild is not available"
        errors=$((errors + 1))
    fi

    # Check simctl
    if command_exists xcrun && xcrun simctl list &>/dev/null; then
        log_success "✓ Simulator tools are available"
    else
        log_error "✗ Simulator tools are not available"
        errors=$((errors + 1))
    fi

    # Check Swift
    if command_exists swift; then
        local swift_version
        swift_version=$(swift --version 2>&1 | head -n1)
        log_success "✓ Swift is available ($swift_version)"
    else
        log_error "✗ Swift is not available"
        errors=$((errors + 1))
    fi

    # Check CocoaPods
    if command_exists pod; then
        log_success "✓ CocoaPods is available (v$(pod --version))"
    else
        log_warning "⚠ CocoaPods is not installed"
    fi

    # Check SwiftLint
    if command_exists swiftlint; then
        log_success "✓ SwiftLint is available (v$(swiftlint version))"
    else
        log_warning "⚠ SwiftLint is not installed"
    fi

    # Check fastlane
    if command_exists fastlane; then
        log_success "✓ fastlane is available"
    else
        log_warning "⚠ fastlane is not installed"
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "iOS environment is ready for development!"
    else
        log_error "iOS environment has $errors critical error(s)"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
iOS Build and Test Environment Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verify    Only verify existing installation
    -m, --minimal   Minimal installation (skip optional tools)
    -f, --full      Full installation (include fastlane)

EXAMPLES:
    $0              # Standard installation
    $0 --verify     # Verify existing installation
    $0 --minimal    # Install only essential components
    $0 --full       # Install all tools including fastlane

REQUIREMENTS:
    - macOS 12.0 or later (recommended)
    - Xcode (from Mac App Store)
    - Apple Developer account (for device deployment)

This script will:
1. Install Homebrew (if not present)
2. Install/verify Xcode Command Line Tools
3. Verify Xcode installation
4. Install CocoaPods for dependency management
5. Install SwiftLint for code linting
6. Install SwiftFormat for code formatting
7. Install xcbeautify for better build output
8. Optionally install fastlane for CI/CD

NOTE: iOS development requires macOS. This script cannot run on Linux.

EOF
}

# Main installation function
main() {
    local verify_only=false
    local minimal=false
    local full=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verify)
                verify_only=true
                shift
                ;;
            -m|--minimal)
                minimal=true
                shift
                ;;
            -f|--full)
                full=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "iOS Build and Test Environment Installation Script"
    log_info "================================================"

    # Check macOS requirement
    check_macos

    if [[ "$verify_only" == true ]]; then
        verify_installation
        return
    fi

    # Run installation steps
    install_homebrew
    install_xcode_cli
    check_xcode

    if [[ "$minimal" != true ]]; then
        install_ios_tools
        install_simulators
    fi

    if [[ "$full" == true ]]; then
        install_fastlane
    fi

    verify_installation

    log_success "Installation completed!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Create an iOS project: File > New > Project in Xcode"
    log_info "  2. Or initialize with: swift package init --type executable"
    log_info "  3. Build from command line: xcodebuild -scheme YourScheme build"
    log_info "  4. Run tests: xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone 15'"
}

# Run main function with all arguments
main "$@"
