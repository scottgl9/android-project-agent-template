#!/bin/bash

# UI Testing Framework Installation Script
# Installs Maestro for cross-platform UI testing (Android and iOS)
# Version: 1.0
# Date: December 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

detect_arch() {
    uname -m
}

# Install Maestro UI Testing Framework
install_maestro() {
    log_info "Installing Maestro UI Testing Framework..."

    if command_exists maestro; then
        local version
        version=$(maestro --version 2>/dev/null || echo "unknown")
        log_success "Maestro already installed: $version"
        return 0
    fi

    # Download and install Maestro
    log_info "Downloading Maestro..."
    curl -Ls "https://get.maestro.mobile.dev" | bash

    # Add to PATH
    export PATH="$PATH:$HOME/.maestro/bin"

    local os
    os=$(detect_os)

    # Add to shell config
    if [[ "$os" == "macos" ]]; then
        if ! grep -q ".maestro/bin" "$HOME/.zshrc" 2>/dev/null; then
            echo 'export PATH="$PATH:$HOME/.maestro/bin"' >> "$HOME/.zshrc"
            log_info "Added Maestro to ~/.zshrc"
        fi
        if [[ -f "$HOME/.bash_profile" ]] && ! grep -q ".maestro/bin" "$HOME/.bash_profile" 2>/dev/null; then
            echo 'export PATH="$PATH:$HOME/.maestro/bin"' >> "$HOME/.bash_profile"
        fi
    else
        if ! grep -q ".maestro/bin" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$PATH:$HOME/.maestro/bin"' >> "$HOME/.bashrc"
            log_info "Added Maestro to ~/.bashrc"
        fi
        if [[ -f "$HOME/.profile" ]] && ! grep -q ".maestro/bin" "$HOME/.profile" 2>/dev/null; then
            echo 'export PATH="$PATH:$HOME/.maestro/bin"' >> "$HOME/.profile"
        fi
    fi

    # Verify installation
    if command_exists maestro || [[ -f "$HOME/.maestro/bin/maestro" ]]; then
        log_success "Maestro installed successfully"
    else
        log_error "Maestro installation failed"
        return 1
    fi
}

# Install additional UI testing dependencies
install_dependencies() {
    local os
    os=$(detect_os)

    log_info "Checking additional dependencies..."

    # Check for Java (required by Maestro)
    if command_exists java; then
        log_success "Java is available"
    else
        log_warning "Java not found. Maestro requires Java."
        log_info "Install Java using: ./scripts/install-android-environment.sh"
    fi

    # Check for ADB (Android)
    if command_exists adb; then
        log_success "ADB is available (Android testing ready)"
    else
        log_warning "ADB not found. Install Android SDK for Android UI testing."
    fi

    # Check for iOS tools (macOS only)
    if [[ "$os" == "macos" ]]; then
        if command_exists xcrun; then
            log_success "Xcode tools available (iOS testing ready)"
        else
            log_warning "Xcode tools not found. Install Xcode for iOS UI testing."
        fi

        # Check for idb (iOS Debug Bridge) - optional but recommended
        if command_exists idb; then
            log_success "idb is available (enhanced iOS testing)"
        else
            log_info "Optional: Install idb for enhanced iOS testing"
            log_info "  macOS: brew install idb-companion"
        fi
    fi

    # Check for required utilities
    if ! command_exists unzip; then
        log_warning "unzip not found, some features may not work"
        log_info "Install with:"
        if [[ "$os" == "macos" ]]; then
            log_info "  brew install unzip"
        else
            log_info "  sudo apt install unzip (Ubuntu/Debian)"
        fi
    fi
}

# Create ui-tests directory structure
create_test_structure() {
    log_info "Creating UI test directory structure..."

    local project_root
    project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

    mkdir -p "$project_root/ui-tests"
    mkdir -p "$project_root/ui-test-results"

    # Create .gitkeep files
    touch "$project_root/ui-tests/.gitkeep"
    touch "$project_root/ui-test-results/.gitkeep"

    # Add ui-test-results to .gitignore if not already there
    if [[ -f "$project_root/.gitignore" ]]; then
        if ! grep -q "ui-test-results" "$project_root/.gitignore" 2>/dev/null; then
            echo "" >> "$project_root/.gitignore"
            echo "# UI Test Results" >> "$project_root/.gitignore"
            echo "ui-test-results/" >> "$project_root/.gitignore"
            log_info "Added ui-test-results/ to .gitignore"
        fi
    fi

    log_success "UI test directory structure created"
}

# Verify installation
verify_installation() {
    log_info "Verifying UI testing setup..."

    local errors=0

    # Check Maestro
    export PATH="$PATH:$HOME/.maestro/bin"
    if command_exists maestro || [[ -f "$HOME/.maestro/bin/maestro" ]]; then
        local version
        version=$("$HOME/.maestro/bin/maestro" --version 2>/dev/null || maestro --version 2>/dev/null || echo "installed")
        log_success "✓ Maestro: $version"
    else
        log_error "✗ Maestro not found"
        errors=$((errors + 1))
    fi

    # Check Java
    if command_exists java; then
        log_success "✓ Java available"
    else
        log_error "✗ Java not available (required)"
        errors=$((errors + 1))
    fi

    # Check platform-specific tools
    local os
    os=$(detect_os)

    if command_exists adb; then
        log_success "✓ Android testing ready (ADB available)"
    else
        log_warning "⚠ Android testing not available (no ADB)"
    fi

    if [[ "$os" == "macos" ]]; then
        if command_exists xcrun; then
            log_success "✓ iOS testing ready (Xcode tools available)"
        else
            log_warning "⚠ iOS testing not available (no Xcode)"
        fi
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "UI testing framework installed successfully!"
        echo ""
        log_info "Next steps:"
        echo "  1. Create UI test files in ui-tests/ directory"
        echo "  2. Run tests with: ./scripts/run-ui-tests.sh [android|ios]"
        echo "  3. Generate tests from PRD: ./scripts/generate-ui-tests.sh"
        echo ""
        log_info "Restart your terminal or run:"
        if [[ "$os" == "macos" ]]; then
            echo "  source ~/.zshrc"
        else
            echo "  source ~/.bashrc"
        fi
    else
        log_error "Installation completed with $errors error(s)"
        return 1
    fi
}

# Show usage
show_usage() {
    cat << EOF
UI Testing Framework Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verify    Only verify existing installation

EXAMPLES:
    $0              # Install UI testing framework
    $0 --verify     # Verify existing installation

This script will:
1. Install Maestro UI testing framework
2. Check for required dependencies (Java, ADB, Xcode tools)
3. Create ui-tests/ directory structure
4. Configure PATH for Maestro

SUPPORTED PLATFORMS:
    - macOS (Android and iOS testing)
    - Linux (Android testing only)

REQUIREMENTS:
    - Java (JDK 11+)
    - Android SDK (for Android testing)
    - Xcode (for iOS testing, macOS only)

EOF
}

# Main function
main() {
    local verify_only=false

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
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "UI Testing Framework Installation"
    log_info "=================================="
    log_info "Platform: $(detect_os) ($(detect_arch))"
    echo ""

    if [[ "$verify_only" == true ]]; then
        verify_installation
        return
    fi

    install_maestro
    install_dependencies
    create_test_structure
    verify_installation
}

main "$@"
