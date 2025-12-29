#!/bin/bash

# Post-Build Hook: Build Status Check
# Runs after build commands to check results and signal next steps
# Version: 1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check last command exit status (passed as argument)
BUILD_EXIT_CODE="${1:-0}"

# Check for build output
check_android_build() {
    if [[ -f "$PROJECT_ROOT/app/build/outputs/apk/debug/app-debug.apk" ]]; then
        local age
        age=$(( $(date +%s) - $(stat -f %m "$PROJECT_ROOT/app/build/outputs/apk/debug/app-debug.apk" 2>/dev/null || echo 0) ))
        if [[ $age -lt 300 ]]; then  # Built in last 5 minutes
            echo "success"
            return
        fi
    fi
    echo "unknown"
}

check_ios_build() {
    # Check DerivedData for recent builds
    local derived_data="$HOME/Library/Developer/Xcode/DerivedData"
    if [[ -d "$derived_data" ]]; then
        local recent
        recent=$(find "$derived_data" -name "*.app" -mmin -5 2>/dev/null | wc -l)
        if [[ "$recent" -gt 0 ]]; then
            echo "success"
            return
        fi
    fi
    echo "unknown"
}

main() {
    if [[ "$BUILD_EXIT_CODE" -eq 0 ]]; then
        echo "BUILD_SUCCESS: Build completed successfully."
        echo "NEXT_STEP: Run tests with ./gradlew test or xcodebuild test"
    else
        echo "BUILD_FAILED: Build failed with exit code $BUILD_EXIT_CODE"
        echo "NEXT_STEP: Fix build errors and rebuild"
    fi

    # Check actual build artifacts
    local android_status
    android_status=$(check_android_build)

    if [[ "$android_status" == "success" ]]; then
        echo "ANDROID_BUILD: Recent APK found"
    fi
}

main
