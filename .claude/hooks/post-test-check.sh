#!/bin/bash

# Post-Test Hook: Test Results Check
# Runs after test commands to check results and signal next steps
# Version: 1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEST_EXIT_CODE="${1:-0}"

# Check Android test results
check_android_tests() {
    local results_dir="$PROJECT_ROOT/app/build/test-results/testDebugUnitTest"

    if [[ -d "$results_dir" ]]; then
        local failures
        failures=$(grep -r "failures=\"[1-9]" "$results_dir" 2>/dev/null | wc -l)
        local errors
        errors=$(grep -r "errors=\"[1-9]" "$results_dir" 2>/dev/null | wc -l)

        if [[ "$failures" -gt 0 || "$errors" -gt 0 ]]; then
            echo "failing"
            return
        fi
        echo "passing"
        return
    fi
    echo "not_run"
}

# Check UI test results
check_ui_tests() {
    local results_dir="$PROJECT_ROOT/ui-test-results"

    if [[ -d "$results_dir" ]]; then
        local latest
        latest=$(ls -t "$results_dir"/report_*.html 2>/dev/null | head -n1)
        if [[ -n "$latest" ]]; then
            if grep -q "Failed.*[1-9]" "$latest" 2>/dev/null; then
                echo "failing"
                return
            fi
            echo "passing"
            return
        fi
    fi
    echo "not_run"
}

main() {
    local unit_status
    unit_status=$(check_android_tests)

    local ui_status
    ui_status=$(check_ui_tests)

    if [[ "$TEST_EXIT_CODE" -eq 0 ]]; then
        echo "TESTS_PASSED: All tests passed successfully."
    else
        echo "TESTS_FAILED: Some tests failed."
    fi

    echo "UNIT_TESTS: $unit_status"
    echo "UI_TESTS: $ui_status"

    # Determine next step
    if [[ "$unit_status" == "failing" ]]; then
        echo "NEXT_STEP: Fix failing unit tests"
    elif [[ "$ui_status" == "failing" ]]; then
        echo "NEXT_STEP: Fix failing UI tests"
    elif [[ "$ui_status" == "not_run" ]]; then
        echo "NEXT_STEP: Run UI tests with ./scripts/run-ui-tests.sh"
    else
        echo "NEXT_STEP: Update documentation and commit changes"
    fi
}

main
