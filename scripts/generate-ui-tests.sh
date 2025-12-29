#!/bin/bash

# UI Test Generator Script
# Generates Maestro UI test flows from PRD.md and user stories
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
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRD_FILE="$PROJECT_ROOT/PRD.md"
TEST_DIR="$PROJECT_ROOT/ui-tests"
UI_TEST_PLAN="$PROJECT_ROOT/UI_TEST_PLAN.md"

# Default app IDs (can be overridden)
ANDROID_APP_ID=""
IOS_BUNDLE_ID=""

show_usage() {
    cat << EOF
UI Test Generator Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -a, --android-id ID     Android application ID (e.g., com.example.app)
    -i, --ios-id ID         iOS bundle identifier (e.g., com.example.app)
    -p, --prd FILE          Path to PRD file (default: PRD.md)
    -o, --output DIR        Output directory (default: ui-tests/)
    --example               Generate example test files

EXAMPLES:
    $0 --example                            # Generate example tests
    $0 -a com.example.myapp                 # Generate with Android app ID
    $0 -a com.example.app -i com.example.app # Generate for both platforms

This script helps generate Maestro UI test files based on:
1. Product Requirements Document (PRD.md)
2. User stories and acceptance criteria
3. Feature specifications

The generated tests should be reviewed and customized for your specific app.

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
            -a|--android-id)
                ANDROID_APP_ID="$2"
                shift 2
                ;;
            -i|--ios-id)
                IOS_BUNDLE_ID="$2"
                shift 2
                ;;
            -p|--prd)
                PRD_FILE="$2"
                shift 2
                ;;
            -o|--output)
                TEST_DIR="$2"
                shift 2
                ;;
            --example)
                generate_examples
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                ;;
        esac
    done
}

# Create directory structure
setup_directories() {
    mkdir -p "$TEST_DIR"
    mkdir -p "$TEST_DIR/flows"
    mkdir -p "$TEST_DIR/shared"
    log_success "Created test directory structure"
}

# Generate example test files
generate_examples() {
    log_info "Generating example UI test files..."

    setup_directories

    local app_id="${ANDROID_APP_ID:-com.example.myapp}"

    # Example: App Launch Test
    cat > "$TEST_DIR/app_launch.yaml" << EOF
# App Launch Test
# Verifies the app launches successfully and shows the main screen
appId: $app_id
---
- launchApp:
    clearState: true
- assertVisible: ".*"  # App should show something
- takeScreenshot: app_launch
EOF
    log_success "Created: app_launch.yaml"

    # Example: Login Flow Test
    cat > "$TEST_DIR/login_flow.yaml" << EOF
# Login Flow Test
# Tests the complete user login flow
appId: $app_id
---
- launchApp:
    clearState: true

# Wait for login screen
- assertVisible:
    text: "Login|Sign In|Welcome"
    optional: false

# Enter credentials
- tapOn:
    text: "Email|Username"
- inputText: "test@example.com"
- hideKeyboard

- tapOn:
    text: "Password"
- inputText: "TestPassword123"
- hideKeyboard

# Submit login
- tapOn:
    text: "Login|Sign In|Submit"

# Verify successful login
- assertVisible:
    text: "Dashboard|Home|Welcome"
    timeout: 10000

- takeScreenshot: login_success
EOF
    log_success "Created: login_flow.yaml"

    # Example: Navigation Test
    cat > "$TEST_DIR/navigation_flow.yaml" << EOF
# Navigation Flow Test
# Tests main app navigation between screens
appId: $app_id
---
- launchApp

# Test bottom navigation or menu
- tapOn:
    text: "Home|Dashboard"
- assertVisible: "Home|Dashboard"

- tapOn:
    text: "Settings|Profile"
- assertVisible: "Settings|Profile"

- tapOn:
    text: "Home|Dashboard"
- assertVisible: "Home|Dashboard"

- takeScreenshot: navigation_complete
EOF
    log_success "Created: navigation_flow.yaml"

    # Example: Form Validation Test
    cat > "$TEST_DIR/form_validation.yaml" << EOF
# Form Validation Test
# Tests form input validation and error handling
appId: $app_id
---
- launchApp

# Navigate to a form (adjust based on your app)
- tapOn:
    text: "Register|Sign Up|Create Account"
    optional: true

# Test empty form submission
- tapOn:
    text: "Submit|Create|Register"
- assertVisible:
    text: "required|invalid|error"
    timeout: 3000

# Test invalid email format
- tapOn:
    text: "Email"
- inputText: "invalid-email"
- hideKeyboard
- tapOn:
    text: "Submit|Create|Register"
- assertVisible:
    text: "valid email|invalid|format"
    optional: true

- takeScreenshot: form_validation
EOF
    log_success "Created: form_validation.yaml"

    # Example: Error Handling Test
    cat > "$TEST_DIR/error_handling.yaml" << EOF
# Error Handling Test
# Tests app behavior under error conditions
appId: $app_id
---
- launchApp:
    clearState: true

# This is a template - customize for your app's error scenarios

# Example: Test offline behavior (if applicable)
# - runScript:
#     file: toggle_airplane_mode.sh

# Example: Test with invalid data
- tapOn:
    text: "Search|Find"
    optional: true
- inputText: "!@#\$%^&*()"
- hideKeyboard

# App should handle gracefully (not crash)
- assertVisible: ".*"

- takeScreenshot: error_handling
EOF
    log_success "Created: error_handling.yaml"

    # Create shared components file
    cat > "$TEST_DIR/shared/login_helper.yaml" << EOF
# Shared Login Helper
# Include this in tests that require authenticated user
appId: $app_id
---
- runFlow:
    file: ../login_flow.yaml
    when:
      visible: "Login|Sign In"
EOF
    log_success "Created: shared/login_helper.yaml"

    # Create test configuration file
    cat > "$TEST_DIR/config.yaml" << EOF
# Maestro Test Configuration
# Global settings for all tests

# App identifiers
android:
  appId: $app_id

ios:
  bundleId: ${IOS_BUNDLE_ID:-$app_id}

# Test settings
settings:
  defaultTimeout: 5000
  screenshotOnFailure: true

# Environment variables for tests
env:
  TEST_USER_EMAIL: "test@example.com"
  TEST_USER_PASSWORD: "TestPassword123"
  API_BASE_URL: "https://api.example.com"
EOF
    log_success "Created: config.yaml"

    echo ""
    log_success "Example UI tests generated in $TEST_DIR/"
    echo ""
    log_info "Next steps:"
    echo "  1. Update app ID in test files"
    echo "  2. Customize tests for your app's UI"
    echo "  3. Run tests: ./scripts/run-ui-tests.sh"
}

# Generate UI Test Plan document
generate_test_plan() {
    log_info "Generating UI Test Plan document..."

    cat > "$UI_TEST_PLAN" << 'EOF'
# UI Test Plan

This document outlines the UI testing strategy for the application.

## Test Categories

### 1. Smoke Tests
Quick tests to verify the app launches and basic functionality works.

| Test | Description | Priority |
|------|-------------|----------|
| App Launch | App starts without crashing | P0 |
| Main Screen | Main content is visible | P0 |
| Navigation | Can navigate between main screens | P0 |

### 2. Authentication Tests
Tests for login, logout, and session management.

| Test | Description | Priority |
|------|-------------|----------|
| Login Success | Valid credentials allow login | P0 |
| Login Failure | Invalid credentials show error | P1 |
| Logout | User can log out successfully | P1 |
| Session Persistence | App remembers logged-in user | P2 |

### 3. Core Feature Tests
Tests for main application features.

| Test | Description | Priority |
|------|-------------|----------|
| [Feature 1] | Description of test | P1 |
| [Feature 2] | Description of test | P1 |
| [Feature 3] | Description of test | P2 |

### 4. Form and Input Tests
Tests for data entry and validation.

| Test | Description | Priority |
|------|-------------|----------|
| Required Fields | Empty required fields show error | P1 |
| Input Validation | Invalid input shows appropriate error | P1 |
| Form Submission | Valid form submits successfully | P1 |

### 5. Error Handling Tests
Tests for graceful error handling.

| Test | Description | Priority |
|------|-------------|----------|
| Network Error | App handles offline gracefully | P1 |
| Invalid Data | App handles malformed data | P2 |
| Timeout | App handles slow responses | P2 |

### 6. Edge Case Tests
Tests for boundary conditions and edge cases.

| Test | Description | Priority |
|------|-------------|----------|
| Empty States | App shows appropriate empty states | P2 |
| Long Text | App handles very long input | P3 |
| Special Characters | App handles unicode/special chars | P3 |

## Test Execution

### Running Tests
```bash
# Run all tests
./scripts/run-ui-tests.sh android
./scripts/run-ui-tests.sh ios

# Run specific test
./scripts/run-ui-tests.sh -t login_flow.yaml android

# Run with retries
./scripts/run-ui-tests.sh -r 3 android
```

### Test Files Location
- Test files: `ui-tests/*.yaml`
- Shared flows: `ui-tests/shared/*.yaml`
- Results: `ui-test-results/`

## Adding New Tests

1. Create a new `.yaml` file in `ui-tests/`
2. Follow the Maestro syntax
3. Run the test to verify it works
4. Update this document with the new test

### Test Template
```yaml
# Test Name
# Description of what this test verifies
appId: com.example.app
---
- launchApp:
    clearState: true

# Test steps here
- assertVisible: "Expected Element"
- tapOn: "Button"
- assertVisible: "Result"

- takeScreenshot: test_name
```

## Priority Definitions

- **P0**: Critical - Must pass for release
- **P1**: High - Should pass for release
- **P2**: Medium - Nice to have
- **P3**: Low - Edge cases

## Maintenance

- Review and update tests when UI changes
- Add tests for new features
- Remove tests for deprecated features
- Keep test names descriptive and consistent
EOF

    log_success "Created: $UI_TEST_PLAN"
}

# Analyze PRD and suggest tests
analyze_prd() {
    if [[ ! -f "$PRD_FILE" ]]; then
        log_warning "PRD file not found: $PRD_FILE"
        log_info "Create PRD.md or specify with --prd option"
        return 1
    fi

    log_info "Analyzing PRD for test generation..."

    echo ""
    echo "========================================"
    echo "PRD Analysis for UI Testing"
    echo "========================================"
    echo ""
    echo "Based on $PRD_FILE, consider creating tests for:"
    echo ""

    # Look for common patterns in PRD
    if grep -qi "login\|auth\|sign.in" "$PRD_FILE" 2>/dev/null; then
        echo "  - Authentication flows (login, logout, registration)"
    fi

    if grep -qi "dashboard\|home\|main" "$PRD_FILE" 2>/dev/null; then
        echo "  - Dashboard/Home screen navigation"
    fi

    if grep -qi "form\|input\|submit" "$PRD_FILE" 2>/dev/null; then
        echo "  - Form submission and validation"
    fi

    if grep -qi "list\|grid\|scroll" "$PRD_FILE" 2>/dev/null; then
        echo "  - List/Grid scrolling and item selection"
    fi

    if grep -qi "search\|filter" "$PRD_FILE" 2>/dev/null; then
        echo "  - Search and filter functionality"
    fi

    if grep -qi "notification\|alert\|push" "$PRD_FILE" 2>/dev/null; then
        echo "  - Notification handling"
    fi

    if grep -qi "setting\|preference\|config" "$PRD_FILE" 2>/dev/null; then
        echo "  - Settings and preferences"
    fi

    if grep -qi "profile\|account\|user" "$PRD_FILE" 2>/dev/null; then
        echo "  - User profile management"
    fi

    echo ""
    echo "========================================"
    echo ""
    log_info "Run with --example to generate starter test files"
}

# Main function
main() {
    parse_args "$@"

    log_info "UI Test Generator"
    log_info "================="
    echo ""

    setup_directories
    analyze_prd
    generate_test_plan

    echo ""
    log_success "UI test generation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Generate example tests: $0 --example"
    echo "  2. Customize tests for your app"
    echo "  3. Run tests: ./scripts/run-ui-tests.sh"
}

main "$@"
