#!/bin/bash

# UI Test Runner Script
# Runs Maestro UI tests for Android and iOS applications
# Supports test generation, execution, and reporting
# Version: 1.0
# Date: December 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/ui-tests"
RESULTS_DIR="$PROJECT_ROOT/ui-test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Default values
PLATFORM="android"
APP_ID=""
SPECIFIC_TEST=""
GENERATE_REPORT=true
CONTINUE_ON_FAILURE=false
MAX_RETRIES=2

# Ensure Maestro is in PATH
export PATH="$PATH:$HOME/.maestro/bin"

detect_os() {
    if [[ "$(uname -s)" == "Darwin" ]]; then echo "macos"; else echo "linux"; fi
}

show_usage() {
    cat << EOF
UI Test Runner Script

Usage: $0 [OPTIONS] [platform]

ARGUMENTS:
    platform        Target platform: android (default), ios, or catalyst

OPTIONS:
    -h, --help          Show this help message
    -a, --app-id ID     Specify application ID/bundle identifier
    -t, --test FILE     Run specific test file only
    -c, --continue      Continue running tests even if one fails
    -r, --retries N     Number of retries for failed tests (default: 2)
    --no-report         Skip HTML report generation
    --list              List available test files

EXAMPLES:
    $0                              # Run all Android UI tests
    $0 ios                          # Run all iOS UI tests (simulator)
    $0 catalyst                     # Run iOS tests via Mac Catalyst
    $0 -a com.example.app android   # Run Android tests for specific app
    $0 -t login_flow.yaml           # Run specific test file
    $0 --list                       # List available tests

PLATFORMS:
    android     Android device or emulator
    ios         iOS Simulator
    catalyst    Mac Catalyst (iOS app running on macOS)

PREREQUISITES:
    - Maestro installed (run ./scripts/install-ui-testing.sh)
    - For Android: Device/emulator connected (adb devices)
    - For iOS: Simulator running (xcrun simctl list devices booted)
    - For Catalyst: Mac Catalyst app built and running

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                ;;
            -a|--app-id)
                APP_ID="$2"
                shift 2
                ;;
            -t|--test)
                SPECIFIC_TEST="$2"
                shift 2
                ;;
            -c|--continue)
                CONTINUE_ON_FAILURE=true
                shift
                ;;
            -r|--retries)
                MAX_RETRIES="$2"
                shift 2
                ;;
            --no-report)
                GENERATE_REPORT=false
                shift
                ;;
            --list)
                list_tests
                exit 0
                ;;
            android|ios|catalyst)
                PLATFORM="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                ;;
        esac
    done
}

# List available test files
list_tests() {
    echo "Available UI Test Files:"
    echo "========================"

    if [[ ! -d "$TEST_DIR" ]]; then
        echo "  No ui-tests/ directory found"
        return
    fi

    local count=0
    for test_file in "$TEST_DIR"/*.yaml "$TEST_DIR"/*.yml; do
        if [[ -f "$test_file" ]]; then
            local name=$(basename "$test_file")
            local lines=$(wc -l < "$test_file" | tr -d ' ')
            echo "  - $name ($lines lines)"
            ((count++))
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "  No test files found in $TEST_DIR/"
        echo ""
        echo "Generate tests with: ./scripts/generate-ui-tests.sh"
    else
        echo ""
        echo "Total: $count test file(s)"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    local errors=0

    # Check Maestro
    if ! command -v maestro &>/dev/null && [[ ! -f "$HOME/.maestro/bin/maestro" ]]; then
        log_error "Maestro not installed"
        log_info "Run: ./scripts/install-ui-testing.sh"
        errors=$((errors + 1))
    else
        log_success "Maestro available"
    fi

    # Platform-specific checks
    if [[ "$PLATFORM" == "android" ]]; then
        if ! command -v adb &>/dev/null; then
            log_error "ADB not found"
            errors=$((errors + 1))
        else
            local devices
            devices=$(adb devices 2>/dev/null | grep -c "device$" || echo "0")
            if [[ "$devices" -eq 0 ]]; then
                log_error "No Android device/emulator connected"
                log_info "Connect a device or start an emulator"
                errors=$((errors + 1))
            else
                log_success "Android device connected ($devices device(s))"
            fi
        fi
    elif [[ "$PLATFORM" == "ios" ]]; then
        if [[ "$(detect_os)" != "macos" ]]; then
            log_error "iOS testing requires macOS"
            errors=$((errors + 1))
        elif ! command -v xcrun &>/dev/null; then
            log_error "Xcode tools not found"
            errors=$((errors + 1))
        else
            local booted
            booted=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted" || echo "0")
            if [[ "$booted" -eq 0 ]]; then
                log_error "No iOS simulator running"
                log_info "Start a simulator: open -a Simulator"
                errors=$((errors + 1))
            else
                log_success "iOS simulator running"
            fi
        fi
    elif [[ "$PLATFORM" == "catalyst" ]]; then
        if [[ "$(detect_os)" != "macos" ]]; then
            log_error "Mac Catalyst requires macOS"
            errors=$((errors + 1))
        else
            # Check macOS version (Catalina 10.15+ required)
            local macos_version
            macos_version=$(sw_vers -productVersion)
            local major_version
            major_version=$(echo "$macos_version" | cut -d. -f1)
            if [[ "$major_version" -ge 10 ]]; then
                log_success "Mac Catalyst supported (macOS $macos_version)"
                log_info "Ensure your Catalyst app is running before tests"
            else
                log_error "Mac Catalyst requires macOS 10.15+"
                errors=$((errors + 1))
            fi
        fi
    fi

    # Check test directory
    if [[ ! -d "$TEST_DIR" ]]; then
        log_warning "Test directory not found: $TEST_DIR"
        mkdir -p "$TEST_DIR"
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Prerequisites check failed with $errors error(s)"
        exit 1
    fi

    echo ""
}

# Capture screenshot on failure
capture_failure_screenshot() {
    local test_name="$1"
    local screenshot_path="$RESULTS_DIR/${test_name}_failure_${TIMESTAMP}.png"

    if [[ "$PLATFORM" == "android" ]]; then
        adb shell screencap -p /sdcard/failure_screenshot.png 2>/dev/null
        adb pull /sdcard/failure_screenshot.png "$screenshot_path" 2>/dev/null || true
        adb shell rm /sdcard/failure_screenshot.png 2>/dev/null || true
    elif [[ "$PLATFORM" == "ios" ]]; then
        xcrun simctl io booted screenshot "$screenshot_path" 2>/dev/null || true
    elif [[ "$PLATFORM" == "catalyst" ]]; then
        # Use screencapture for Mac Catalyst apps
        screencapture -x "$screenshot_path" 2>/dev/null || true
    fi

    if [[ -f "$screenshot_path" ]]; then
        log_info "Screenshot saved: $screenshot_path"
    fi
}

# Run a single test with retries
run_single_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .yaml)
    test_name=$(basename "$test_name" .yml)

    local attempt=1
    local success=false

    while [[ $attempt -le $((MAX_RETRIES + 1)) ]]; do
        if [[ $attempt -gt 1 ]]; then
            log_warning "Retry $((attempt - 1))/$MAX_RETRIES for $test_name"
            sleep 2
        fi

        log_step "Running: $test_name (attempt $attempt)"

        local output_file="$RESULTS_DIR/${test_name}_${TIMESTAMP}.xml"

        # Run Maestro test
        if maestro test "$test_file" --format junit --output "$output_file" 2>&1; then
            log_success "$test_name PASSED"
            success=true
            break
        else
            log_error "$test_name FAILED (attempt $attempt)"
            ((attempt++))
        fi
    done

    if [[ "$success" == false ]]; then
        capture_failure_screenshot "$test_name"
        return 1
    fi

    return 0
}

# Run all tests
run_tests() {
    log_step "Running UI tests for $PLATFORM..."
    echo ""

    mkdir -p "$RESULTS_DIR"

    local passed=0
    local failed=0
    local skipped=0
    local failed_tests=()

    # Determine which tests to run
    local test_files=()

    if [[ -n "$SPECIFIC_TEST" ]]; then
        if [[ -f "$TEST_DIR/$SPECIFIC_TEST" ]]; then
            test_files+=("$TEST_DIR/$SPECIFIC_TEST")
        elif [[ -f "$SPECIFIC_TEST" ]]; then
            test_files+=("$SPECIFIC_TEST")
        else
            log_error "Test file not found: $SPECIFIC_TEST"
            exit 1
        fi
    else
        for f in "$TEST_DIR"/*.yaml "$TEST_DIR"/*.yml; do
            [[ -f "$f" ]] && test_files+=("$f")
        done
    fi

    if [[ ${#test_files[@]} -eq 0 ]]; then
        log_warning "No UI test files found in $TEST_DIR/"
        log_info "Create test files or run: ./scripts/generate-ui-tests.sh"
        exit 0
    fi

    log_info "Found ${#test_files[@]} test file(s)"
    echo ""

    # Run each test
    for test_file in "${test_files[@]}"; do
        if run_single_test "$test_file"; then
            ((passed++))
        else
            ((failed++))
            failed_tests+=("$(basename "$test_file")")

            if [[ "$CONTINUE_ON_FAILURE" == false ]]; then
                log_error "Stopping due to test failure (use -c to continue)"
                break
            fi
        fi
        echo ""
    done

    # Print summary
    echo ""
    echo "========================================"
    echo "         UI Test Summary"
    echo "========================================"
    echo "Platform:  $PLATFORM"
    echo "Timestamp: $TIMESTAMP"
    echo "----------------------------------------"
    printf "${GREEN}Passed:${NC}    %d\n" "$passed"
    printf "${RED}Failed:${NC}    %d\n" "$failed"
    echo "Total:     $((passed + failed))"
    echo "----------------------------------------"

    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for t in "${failed_tests[@]}"; do
            echo "  - $t"
        done
    fi

    echo ""
    echo "Results saved to: $RESULTS_DIR/"
    echo "========================================"

    # Generate HTML report
    if [[ "$GENERATE_REPORT" == true ]]; then
        generate_html_report "$passed" "$failed" "${failed_tests[@]}"
    fi

    # Return appropriate exit code
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Generate HTML report
generate_html_report() {
    local passed="$1"
    local failed="$2"
    shift 2
    local failed_tests=("$@")

    local report_file="$RESULTS_DIR/report_${TIMESTAMP}.html"

    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>UI Test Report - $TIMESTAMP</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .stat { padding: 20px; border-radius: 8px; text-align: center; flex: 1; }
        .stat.passed { background: #d4edda; color: #155724; }
        .stat.failed { background: #f8d7da; color: #721c24; }
        .stat.total { background: #e2e3e5; color: #383d41; }
        .stat h2 { margin: 0; font-size: 36px; }
        .stat p { margin: 5px 0 0 0; }
        .failed-list { background: #fff3cd; padding: 15px; border-radius: 8px; margin-top: 20px; }
        .failed-list h3 { margin-top: 0; color: #856404; }
        .failed-list ul { margin-bottom: 0; }
        .meta { color: #666; font-size: 14px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>UI Test Report</h1>
        <div class="summary">
            <div class="stat passed">
                <h2>$passed</h2>
                <p>Passed</p>
            </div>
            <div class="stat failed">
                <h2>$failed</h2>
                <p>Failed</p>
            </div>
            <div class="stat total">
                <h2>$((passed + failed))</h2>
                <p>Total</p>
            </div>
        </div>
EOF

    if [[ ${#failed_tests[@]} -gt 0 ]]; then
        cat >> "$report_file" << EOF
        <div class="failed-list">
            <h3>Failed Tests</h3>
            <ul>
EOF
        for t in "${failed_tests[@]}"; do
            echo "                <li>$t</li>" >> "$report_file"
        done
        cat >> "$report_file" << EOF
            </ul>
        </div>
EOF
    fi

    cat >> "$report_file" << EOF
        <div class="meta">
            <p><strong>Platform:</strong> $PLATFORM</p>
            <p><strong>Timestamp:</strong> $TIMESTAMP</p>
            <p><strong>Results Directory:</strong> $RESULTS_DIR/</p>
        </div>
    </div>
</body>
</html>
EOF

    log_info "HTML report: $report_file"
}

# Main
main() {
    parse_args "$@"

    echo ""
    log_info "UI Test Runner"
    log_info "=============="
    log_info "Platform: $PLATFORM"
    log_info "Test Directory: $TEST_DIR"
    echo ""

    check_prerequisites
    run_tests
}

main "$@"
