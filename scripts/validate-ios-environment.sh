#!/bin/bash

# iOS Environment Validation Script for Agents
# This script provides a quick validation of the iOS development environment
# Returns exit code 0 if environment is ready, 1 if there are issues

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

# Main validation function
validate_environment() {
    local errors=0
    local warnings=0

    echo "=== iOS Environment Validation ==="

    # Check if running on macOS
    if [[ "$(detect_os)" != "macos" ]]; then
        log_error "iOS development requires macOS"
        log_info "Current OS: $(uname -s)"
        return 1
    fi

    echo "OS: macOS $(get_macos_version) ($(detect_arch))"
    echo ""

    # Check Xcode
    echo -n "Checking Xcode... "
    if [[ -d "/Applications/Xcode.app" ]]; then
        local xcode_version
        xcode_version=$(xcodebuild -version 2>/dev/null | head -n1 || echo "Unknown")
        echo -e "${GREEN}✓${NC} Installed ($xcode_version)"
    else
        echo -e "${RED}✗${NC} Not installed"
        log_error "Xcode is not installed. Please install from the Mac App Store."
        errors=$((errors + 1))
    fi

    # Check Xcode Command Line Tools
    echo -n "Checking Xcode CLI Tools... "
    if xcode-select -p &>/dev/null; then
        echo -e "${GREEN}✓${NC} Available"
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "Xcode Command Line Tools not installed. Run: xcode-select --install"
        errors=$((errors + 1))
    fi

    # Check xcodebuild
    echo -n "Checking xcodebuild... "
    if command_exists xcodebuild; then
        echo -e "${GREEN}✓${NC} Available"
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "xcodebuild is not available"
        errors=$((errors + 1))
    fi

    # Check Swift
    echo -n "Checking Swift... "
    if command_exists swift; then
        local swift_version
        swift_version=$(swift --version 2>&1 | grep -o 'Swift version [0-9.]*' | head -n1)
        echo -e "${GREEN}✓${NC} Available ($swift_version)"
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "Swift is not available"
        errors=$((errors + 1))
    fi

    # Check Simulator
    echo -n "Checking Simulator... "
    if command_exists xcrun && xcrun simctl list devices &>/dev/null; then
        local sim_count
        sim_count=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone" || echo "0")
        if [[ "$sim_count" -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Available ($sim_count iPhone simulator(s))"
        else
            echo -e "${YELLOW}⚠${NC} No iPhone simulators available"
            log_warning "No iPhone simulators found. Download from Xcode > Settings > Platforms"
            warnings=$((warnings + 1))
        fi
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "Simulator tools not available"
        errors=$((errors + 1))
    fi

    # Check CocoaPods
    echo -n "Checking CocoaPods... "
    if command_exists pod; then
        local pod_version
        pod_version=$(pod --version)
        echo -e "${GREEN}✓${NC} Available (v$pod_version)"
    else
        echo -e "${YELLOW}⚠${NC} Not installed"
        log_warning "CocoaPods not installed. Run: brew install cocoapods"
        warnings=$((warnings + 1))
    fi

    # Check SwiftLint
    echo -n "Checking SwiftLint... "
    if command_exists swiftlint; then
        local swiftlint_version
        swiftlint_version=$(swiftlint version)
        echo -e "${GREEN}✓${NC} Available (v$swiftlint_version)"
    else
        echo -e "${YELLOW}⚠${NC} Not installed"
        log_warning "SwiftLint not installed. Run: brew install swiftlint"
        warnings=$((warnings + 1))
    fi

    # Check SwiftFormat
    echo -n "Checking SwiftFormat... "
    if command_exists swiftformat; then
        local swiftformat_version
        swiftformat_version=$(swiftformat --version)
        echo -e "${GREEN}✓${NC} Available (v$swiftformat_version)"
    else
        echo -e "${YELLOW}⚠${NC} Not installed"
        log_warning "SwiftFormat not installed. Run: brew install swiftformat"
        warnings=$((warnings + 1))
    fi

    # Check fastlane
    echo -n "Checking fastlane... "
    if command_exists fastlane; then
        echo -e "${GREEN}✓${NC} Available"
    else
        echo -e "${YELLOW}⚠${NC} Not installed (optional)"
        log_info "fastlane is optional. Install with: brew install fastlane"
    fi

    # Check xcbeautify
    echo -n "Checking xcbeautify... "
    if command_exists xcbeautify; then
        echo -e "${GREEN}✓${NC} Available"
    else
        echo -e "${YELLOW}⚠${NC} Not installed"
        log_warning "xcbeautify not installed. Run: brew install xcbeautify"
        warnings=$((warnings + 1))
    fi

    echo ""
    echo "=== Validation Summary ==="

    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            log_success "Environment is fully ready for iOS development!"
        else
            log_success "Environment is ready with $warnings warning(s)"
        fi
        echo ""
        log_info "You can now use iOS development tools:"
        echo "  - xcodebuild - Build and test from command line"
        echo "  - swift - Swift compiler and package manager"
        echo "  - xcrun simctl - Simulator control"
        echo "  - pod - CocoaPods dependency management"
        echo "  - swiftlint - Swift code linting"
        echo "  - swiftformat - Swift code formatting"
        return 0
    else
        log_error "Environment has $errors error(s) and $warnings warning(s)"
        echo ""
        log_info "To fix issues, run the installation script:"
        echo "  ./scripts/install-ios-environment.sh"
        return 1
    fi
}

# Show environment details
show_environment_details() {
    echo ""
    echo "=== Environment Details ==="
    echo "OS: macOS $(get_macos_version)"
    echo "Architecture: $(detect_arch)"

    if command_exists xcodebuild; then
        echo ""
        echo "Xcode Info:"
        xcodebuild -version 2>/dev/null
    fi

    if command_exists swift; then
        echo ""
        echo "Swift Version:"
        swift --version 2>&1 | head -n2
    fi

    if command_exists xcrun && xcrun simctl list devices available &>/dev/null; then
        echo ""
        echo "Available iOS Simulators:"
        xcrun simctl list devices available 2>/dev/null | grep "iPhone" | head -10
    fi

    echo ""
    echo "Developer Directory:"
    xcode-select -p 2>/dev/null || echo "Not set"
}

# Usage function
show_usage() {
    cat << EOF
iOS Environment Validation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --details   Show detailed environment information
    -q, --quiet     Quiet mode (minimal output)

EXAMPLES:
    $0              # Basic validation
    $0 --details    # Validation with environment details
    $0 --quiet      # Quiet validation (exit code only)

REQUIREMENTS:
    - macOS (iOS development requires a Mac)
    - Xcode installed from Mac App Store

EXIT CODES:
    0   Environment is ready
    1   Environment has errors

This script validates:
- macOS and Xcode installation
- Xcode Command Line Tools
- Swift compiler availability
- iOS Simulator availability
- Development tools (CocoaPods, SwiftLint, etc.)

EOF
}

# Main function
main() {
    local show_details=false
    local quiet_mode=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--details)
                show_details=true
                shift
                ;;
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    if [[ "$quiet_mode" == true ]]; then
        validate_environment >/dev/null 2>&1
        exit $?
    fi

    validate_environment
    local exit_code=$?

    if [[ "$show_details" == true ]]; then
        show_environment_details
    fi

    exit $exit_code
}

# Run main function with all arguments
main "$@"
