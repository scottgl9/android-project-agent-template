#!/bin/bash

# Android Environment Validation Script for Agents
# This script provides a quick validation of the Android development environment
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

# Main validation function
validate_environment() {
    local errors=0
    local warnings=0
    
    echo "=== Android Environment Validation ==="
    echo ""
    
    # Check Java
    echo -n "Checking Java... "
    if command_exists java && command_exists javac; then
        local java_version
        java_version=$(java -version 2>&1 | head -n1)
        echo -e "${GREEN}✓${NC} Available ($java_version)"
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "Java JDK is not installed or not in PATH"
        errors=$((errors + 1))
    fi

    echo -n "Checking JAVA_HOME... "
    if [[ -n "$JAVA_HOME" && -d "$JAVA_HOME" ]]; then
        echo -e "${GREEN}✓${NC} Set ($JAVA_HOME)"
    else
        echo -e "${RED}✗${NC} Not set or directory missing"
        log_error "JAVA_HOME is not set or points to a non-existent directory"
        errors=$((errors + 1))
    fi
    
    # Check Gradle
    echo -n "Checking Gradle... "
    if command_exists gradle; then
        local gradle_version
        gradle_version=$(gradle --version 2>/dev/null | grep "Gradle " | awk '{print $2}')
        echo -e "${GREEN}✓${NC} Available (version $gradle_version)"
    else
        echo -e "${RED}✗${NC} Not available"
        log_error "Gradle is not installed or not in PATH"
        errors=$((errors + 1))
    fi
    
    # Check Android tools
    local tools=("adb" "fastboot" "sdkmanager" "avdmanager" "emulator")
    for tool in "${tools[@]}"; do
        echo -n "Checking $tool... "
        if command_exists "$tool"; then
            echo -e "${GREEN}✓${NC} Available"
        else
            echo -e "${RED}✗${NC} Not available"
            log_error "$tool is not installed or not in PATH"
            errors=$((errors + 1))
        fi
    done
    
    # Check environment variables
    echo -n "Checking ANDROID_HOME... "
    if [[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]]; then
        echo -e "${GREEN}✓${NC} Set ($ANDROID_HOME)"
    else
        echo -e "${RED}✗${NC} Not set or directory missing"
        log_error "ANDROID_HOME is not set or points to non-existent directory"
        errors=$((errors + 1))
    fi
    
    echo -n "Checking ANDROID_SDK_ROOT... "
    if [[ -n "$ANDROID_SDK_ROOT" && -d "$ANDROID_SDK_ROOT" ]]; then
        echo -e "${GREEN}✓${NC} Set ($ANDROID_SDK_ROOT)"
    else
        echo -e "${YELLOW}⚠${NC} Not set or directory missing"
        log_warning "ANDROID_SDK_ROOT is not set (optional but recommended)"
        warnings=$((warnings + 1))
    fi
    
    # Check SDK components
    if command_exists sdkmanager; then
        echo -n "Checking SDK platforms... "
        local platforms
        platforms=$(sdkmanager --list_installed 2>/dev/null | grep "platforms;" | wc -l)
        if [[ $platforms -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Found $platforms platform(s)"
        else
            echo -e "${YELLOW}⚠${NC} No platforms installed"
            log_warning "No Android platforms are installed"
            warnings=$((warnings + 1))
        fi
        
        echo -n "Checking build tools... "
        local build_tools
        build_tools=$(sdkmanager --list_installed 2>/dev/null | grep "build-tools;" | wc -l)
        if [[ $build_tools -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Found $build_tools version(s)"
        else
            echo -e "${RED}✗${NC} No build tools installed"
            log_error "No build tools are installed"
            errors=$((errors + 1))
        fi
    fi
    
    # Check AVDs
    if command_exists avdmanager; then
        echo -n "Checking AVDs... "
        local avds
        avds=$(avdmanager list avd 2>/dev/null | grep "Name:" | wc -l)
        if [[ $avds -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} Found $avds AVD(s)"
            if avdmanager list avd 2>/dev/null | grep -q "test_avd"; then
                echo -e "  ${GREEN}✓${NC} Test AVD 'test_avd' is available"
            else
                echo -e "  ${YELLOW}⚠${NC} Test AVD 'test_avd' not found"
                log_warning "Default test AVD is not available"
                warnings=$((warnings + 1))
            fi
        else
            echo -e "${YELLOW}⚠${NC} No AVDs found"
            log_warning "No Android Virtual Devices are configured"
            warnings=$((warnings + 1))
        fi
    fi
    
    # Check device connectivity
    if command_exists adb; then
        echo -n "Checking device connectivity... "
        local devices
        devices=$(adb devices 2>/dev/null | grep -c "device$")
        if [[ $devices -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} $devices device(s) connected"
        else
            echo -e "${YELLOW}⚠${NC} No devices connected"
            log_info "This is normal if no physical devices or running emulators"
        fi
    fi
    
    echo ""
    echo "=== Validation Summary ==="
    
    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            log_success "🎉 Environment is fully ready for Android development!"
        else
            log_success "✅ Environment is ready with $warnings warning(s)"
        fi
        echo ""
        log_info "You can now use Android development tools:"
        echo "  • gradle - Build automation tool"
        echo "  • adb - Android Debug Bridge"
        echo "  • fastboot - Device flashing tool"
        echo "  • sdkmanager - SDK package management"
        echo "  • avdmanager - Virtual device management"
        echo "  • emulator - Android emulator"
        return 0
    else
        log_error "❌ Environment has $errors error(s) and $warnings warning(s)"
        echo ""
        log_info "To fix issues, run the installation script:"
        echo "  ./install-android-environment.sh"
        return 1
    fi
}

# Show environment details
show_environment_details() {
    echo ""
    echo "=== Environment Details ==="
    
    if [[ -n "$ANDROID_HOME" ]]; then
        echo "ANDROID_HOME: $ANDROID_HOME"
    fi
    
    if [[ -n "$ANDROID_SDK_ROOT" ]]; then
        echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
    fi
    
    echo -n "Java Version: "
    if command_exists java; then
        java -version 2>&1 | head -n1
    else
        echo "Not available"
    fi
    
    if command_exists sdkmanager; then
        echo ""
        echo "Installed SDK Packages:"
        sdkmanager --list_installed 2>/dev/null | head -10
    fi
    
    if command_exists avdmanager; then
        echo ""
        echo "Available AVDs:"
        avdmanager list avd 2>/dev/null | grep -E "(Name:|Path:)" || echo "  No AVDs found"
    fi
}

# Usage function
show_usage() {
    cat << EOF
Android Environment Validation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -d, --details   Show detailed environment information
    -q, --quiet     Quiet mode (minimal output)
    
EXAMPLES:
    $0              # Basic validation
    $0 --details    # Validation with environment details
    $0 --quiet      # Quiet validation (exit code only)

EXIT CODES:
    0   Environment is ready
    1   Environment has errors

This script validates:
• Java JDK installation
• Gradle build tool availability
• Android SDK tools availability
• Environment variables configuration
• SDK components installation
• AVD availability
• Device connectivity (informational)

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