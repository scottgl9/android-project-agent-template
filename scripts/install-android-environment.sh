#!/bin/bash

# Android Build and Test Environment Installation Script
# This script automatically sets up a complete Android development environment on Linux and macOS
# Version: 2.0
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

# Function to detect Linux distribution
detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif command_exists lsb_release; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Function to detect JDK 21 installation path
detect_java_home() {
    if [[ "$(detect_os)" == "macos" ]]; then
        if command_exists /usr/libexec/java_home; then
            /usr/libexec/java_home -v 21 2>/dev/null && return 0
        fi
    fi

    local candidates=(
        "/usr/lib/jvm/java-1.21.0-openjdk-amd64"
        "/usr/lib/jvm/java-21-openjdk-amd64"
        "/usr/lib/jvm/java-21-openjdk"
        "/usr/lib/jvm/jdk-21"
        "/usr/lib/jvm/jdk-21.0"
    )

    for path in "${candidates[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    if command_exists javac; then
        local resolved
        if [[ "$(detect_os)" == "macos" ]]; then
            resolved=$(realpath "$(command -v javac)" 2>/dev/null)
        else
            resolved=$(readlink -f "$(command -v javac)" 2>/dev/null)
        fi

        if [[ -n "$resolved" ]]; then
            # Navigate up from bin/javac to home
            local bin_dir
            bin_dir=$(dirname "$resolved")
            echo "$(dirname "$bin_dir")"
            return 0
        fi
    fi

    echo ""
    return 1
}

append_env_block() {
    local file="$1"
    local block="$2"

    if [[ ! -f "$file" ]]; then
        touch "$file"
    fi

    # Check if our specific configuration already exists
    if ! grep -q "Added by android-project-agent-template" "$file" 2>/dev/null; then
        printf "%s\n" "$block" >> "$file"
        log_success "Environment variables appended to $file"
    else
        log_warning "Android environment already configured in $file"
    fi
}

# Function to install Java
install_java() {
    log_info "Installing Java Development Kit (JDK 21)..."

    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        if ! command_exists brew; then
            log_error "Homebrew is required for automatic installation on macOS."
            log_info "Please install Homebrew: https://brew.sh/"
            exit 1
        fi
        log_info "Installing OpenJDK 21 via Homebrew..."
        brew install openjdk@21

        # Symlink for system Java wrappers
        sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk 2>/dev/null || true
    elif [[ "$os" == "linux" ]]; then
        local distro
        distro=$(detect_linux_distro)
        case $distro in
            ubuntu|debian)
                sudo apt update
                sudo apt install -y openjdk-21-jdk
                ;;
            fedora)
                sudo dnf install -y java-21-openjdk-devel
                ;;
            centos|rhel)
                sudo yum install -y java-21-openjdk-devel
                ;;
            arch)
                sudo pacman -S --noconfirm jdk21-openjdk
                ;;
            *)
                log_error "Unsupported distribution: $distro"
                log_info "Please install OpenJDK 21 manually"
                exit 1
                ;;
        esac
    else
        log_error "Unsupported OS: $os"
        exit 1
    fi

    # Verify Java installation
    # On mac, we might need to set PATH temporarily or rely on java_home
    if [[ "$os" == "macos" ]]; then
        export JAVA_HOME=$(/usr/libexec/java_home -v 21)
        export PATH=$JAVA_HOME/bin:$PATH
    fi

    if command_exists java && command_exists javac; then
        log_success "Java installed successfully"
        java -version 2>&1 | head -n 1
    else
        log_error "Java installation failed"
        exit 1
    fi
}

# Function to install Gradle
install_gradle() {
    log_info "Installing Gradle build tool..."

    local os
    os=$(detect_os)

    # Prefer Homebrew on macOS
    if [[ "$os" == "macos" ]] && command_exists brew; then
        if brew list gradle &>/dev/null; then
            log_warning "Gradle is already installed via Homebrew"
        else
            brew install gradle
            log_success "Gradle installed via Homebrew"
        fi
        return 0
    fi

    local gradle_version="8.10.2"
    local gradle_dir="$HOME/.gradle-install"
    local gradle_url="https://services.gradle.org/distributions/gradle-${gradle_version}-bin.zip"
    local gradle_zip="$gradle_dir/gradle-${gradle_version}-bin.zip"

    # Create Gradle installation directory
    mkdir -p "$gradle_dir"

    # Check if Gradle is already installed
    if command_exists gradle; then
        local current_version
        current_version=$(gradle --version | grep "Gradle " | awk '{print $2}')
        log_warning "Gradle $current_version is already installed"
        return 0
    fi

    # Download Gradle
    log_info "Downloading Gradle $gradle_version..."
    if command_exists wget; then
        wget -O "$gradle_zip" "$gradle_url"
    elif command_exists curl; then
        curl -L -o "$gradle_zip" "$gradle_url"
    else
        log_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    # Extract Gradle
    log_info "Extracting Gradle..."
    cd "$gradle_dir"
    unzip -q -o "$gradle_zip"

    # Create symlink for easier access
    ln -sf "$gradle_dir/gradle-$gradle_version" "$gradle_dir/current"

    # Clean up
    rm -f "$gradle_zip"

    log_success "Gradle $gradle_version installed successfully"
}

# Function to create Android SDK directory
create_sdk_directory() {
    log_info "Creating Android SDK directory structure..."

    local sdk_dir="$HOME/Android/Sdk"
    mkdir -p "$sdk_dir"

    if [[ -d "$sdk_dir" ]]; then
        log_success "Android SDK directory created: $sdk_dir"
    else
        log_error "Failed to create Android SDK directory"
        exit 1
    fi
}

# Function to download and setup command line tools
setup_command_line_tools() {
    log_info "Downloading Android Command Line Tools..."

    local sdk_dir="$HOME/Android/Sdk"
    local os
    os=$(detect_os)
    local tools_url

    if [[ "$os" == "macos" ]]; then
        tools_url="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
    else
        tools_url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    fi

    local tools_zip="$sdk_dir/commandlinetools-latest.zip"

    # Download command line tools
    if command_exists wget; then
        wget -O "$tools_zip" "$tools_url"
    elif command_exists curl; then
        curl -L -o "$tools_zip" "$tools_url"
    else
        log_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    # Extract tools
    log_info "Extracting command line tools..."
    cd "$sdk_dir"
    unzip -q -o "$tools_zip"

    # Create proper directory structure
    mkdir -p cmdline-tools/latest
    # Move contents if they aren't already there (idempotency)
    if [[ -d "cmdline-tools/bin" ]]; then
        mv cmdline-tools/bin cmdline-tools/lib cmdline-tools/source.properties cmdline-tools/NOTICE.txt cmdline-tools/latest/ 2>/dev/null || true
    fi

    # Clean up
    rm -f "$tools_zip"

    log_success "Command line tools installed and configured"
}

# Function to install SDK components
install_sdk_components() {
    log_info "Installing Android SDK components..."

    local sdk_dir="$HOME/Android/Sdk"
    export ANDROID_HOME="$sdk_dir"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

    # Accept licenses automatically
    yes | sdkmanager --licenses >/dev/null 2>&1 || true

    # Install essential components
    log_info "Installing platform-tools, build-tools, and platforms..."
    echo "y" | sdkmanager "platform-tools" "build-tools;35.0.0" "build-tools;34.0.0" "platforms;android-35" "platforms;android-34"

    # Install emulator
    log_info "Installing Android emulator..."
    echo "y" | sdkmanager "emulator"

    # Determine appropriate system image based on architecture
    local arch
    arch=$(detect_arch)
    local image_arch="x86_64"
    if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
        image_arch="arm64-v8a"
    fi

    # Install system image for testing
    log_info "Installing system image for emulator ($image_arch)..."
    echo "y" | sdkmanager "system-images;android-34;google_apis;${image_arch}"

    log_success "Android SDK components installed successfully"
}

# Function to configure environment variables
configure_environment() {
    log_info "Configuring environment variables..."

    local java_home=${JAVA_HOME:-$(detect_java_home)}

    if [[ -n "$java_home" ]]; then
        export JAVA_HOME="$java_home"
        log_success "Using JAVA_HOME=$JAVA_HOME"
    else
        log_warning "JAVA_HOME could not be determined automatically. Please set it manually to your JDK 21 installation."
    fi

    local os
    os=$(detect_os)

    local env_block="
# Android SDK and Java environment variables - Added by android-project-agent-template
export JAVA_HOME=\"$java_home\"
export ANDROID_HOME=\"\$HOME/Android/Sdk\"
export ANDROID_SDK_ROOT=\"\$HOME/Android/Sdk\"
"
    # Only add GRADLE_HOME if we installed it manually (not via brew)
    if [[ -d "$HOME/.gradle-install/current" ]]; then
        env_block="$env_block
export GRADLE_HOME=\"\$HOME/.gradle-install/current\"
export PATH=\"\$PATH:\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator:\$GRADLE_HOME/bin\"
"
    else
        env_block="$env_block
export PATH=\"\$PATH:\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/emulator\"
"
    fi

    if [[ "$os" == "macos" ]]; then
        append_env_block "$HOME/.zshrc" "$env_block"
        # Also add to .bash_profile for users who use bash
        append_env_block "$HOME/.bash_profile" "$env_block"
        source "$HOME/.zshrc" 2>/dev/null || true
    else
        append_env_block "$HOME/.bashrc" "$env_block"
        append_env_block "$HOME/.profile" "$env_block"
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
}

# Function to create test AVD
create_test_avd() {
    log_info "Creating test Android Virtual Device..."

    export ANDROID_HOME="$HOME/Android/Sdk"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

    local arch
    arch=$(detect_arch)
    local image_arch="x86_64"
    if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
        image_arch="arm64-v8a"
    fi

    # Create AVD if it doesn't exist
    if ! avdmanager list avd | grep -q "test_avd"; then
        echo "no" | avdmanager create avd -n test_avd -k "system-images;android-34;google_apis;${image_arch}" >/dev/null
        log_success "Test AVD 'test_avd' created successfully using ${image_arch}"
    else
        log_warning "Test AVD 'test_avd' already exists"
    fi
}

# Function to verify installation
verify_installation() {
    log_info "Verifying Android environment installation..."

    export ANDROID_HOME="$HOME/Android/Sdk"
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

    local errors=0

    # Check Java
    if command_exists java && command_exists javac; then
        log_success "✓ Java is available ($(java -version 2>&1 | head -n1))"
    else
        log_error "✗ Java is not available"
        errors=$((errors + 1))
    fi

    # Check JAVA_HOME
    if [[ -n "$JAVA_HOME" && -d "$JAVA_HOME" ]]; then
        log_success "✓ JAVA_HOME is set ($JAVA_HOME)"
    else
        log_error "✗ JAVA_HOME is not set or points to a missing directory"
        errors=$((errors + 1))
    fi

    # Check Gradle
    if command_exists gradle; then
        local gradle_version
        gradle_version=$(gradle --version 2>&1 | grep "Gradle " | awk '{print $2}')
        log_success "✓ Gradle is available (version $gradle_version)"
    else
        log_error "✗ Gradle is not available"
        errors=$((errors + 1))
    fi

    # Check Android tools
    local tools=("adb" "fastboot" "sdkmanager" "avdmanager" "emulator")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            local version=""
            case $tool in
                "adb"|"fastboot") version="$(${tool} --version 2>&1 | head -n1)" ;;
                "sdkmanager") version="$(${tool} --version 2>&1)" ;;
                "emulator") version="$(${tool} -version 2>&1 | head -n1)" ;;
                "avdmanager") version="available" ;;
            esac
            log_success "✓ $tool is available ($version)"
        else
            log_error "✗ $tool is not available"
            errors=$((errors + 1))
        fi
    done

    # Check installed packages
    if command_exists sdkmanager; then
        log_info "Installed SDK packages:"
        sdkmanager --list_installed | grep -E "(Path|platforms|build-tools|platform-tools|emulator|system-images)" | head -10
    fi

    # Check AVD
    if avdmanager list avd | grep -q "test_avd"; then
        log_success "✓ Test AVD is available"
    else
        log_warning "⚠ Test AVD is not available"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Android environment installation completed successfully!"
        local os
        os=$(detect_os)
        if [[ "$os" == "macos" ]]; then
            log_info "Please restart your terminal or run 'source ~/.zshrc' to use the tools immediately."
        else
            log_info "Please restart your terminal or run 'source ~/.bashrc' to use the tools immediately."
        fi
    else
        log_error "Installation completed with $errors errors. Please check the output above."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Android Build and Test Environment Installation Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verify    Only verify existing installation
    -f, --force     Force reinstallation even if components exist

EXAMPLES:
    $0              # Install complete Android environment
    $0 --verify     # Verify existing installation
    $0 --force      # Force complete reinstallation

SUPPORTED PLATFORMS:
    - macOS (Intel and Apple Silicon)
    - Linux (Ubuntu, Debian, Fedora, CentOS, RHEL, Arch)

This script will:
1. Install Java Development Kit (OpenJDK 21)
2. Install Gradle build tool (via Homebrew on macOS, manual on Linux)
3. Download and setup Android Command Line Tools
4. Install Android SDK components (platform-tools, build-tools, platforms)
5. Configure environment variables in ~/.zshrc (macOS) or ~/.bashrc (Linux)
6. Create a test Android Virtual Device (adapts to ARM64/x86_64)
7. Verify the complete installation

EOF
}

# Main installation function
main() {
    local force_install=false
    local verify_only=false

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
            -f|--force)
                force_install=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "Android Build and Test Environment Installation Script"
    log_info "================================================"
    log_info "Running on $(detect_os) ($(detect_arch))"

    if [[ "$verify_only" == true ]]; then
        verify_installation
        return
    fi

    # Check if Android environment already exists
    if [[ -d "$HOME/Android/Sdk" ]] && [[ "$force_install" != true ]]; then
        log_warning "Android SDK directory already exists at $HOME/Android/Sdk"
        log_info "Use --force to reinstall or --verify to check existing installation"
        exit 1
    fi

    # Run installation steps
    install_java
    install_gradle
    create_sdk_directory
    setup_command_line_tools
    install_sdk_components
    configure_environment
    create_test_avd
    verify_installation

    local os
    os=$(detect_os)
    if [[ "$os" == "macos" ]]; then
        log_success "Installation completed! Please restart your terminal or run 'source ~/.zshrc'"
    else
        log_success "Installation completed! Please restart your terminal or run 'source ~/.bashrc'"
    fi
}

# Run main function with all arguments
main "$@"
