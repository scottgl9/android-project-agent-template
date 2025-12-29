#!/bin/bash

# Orchestration Script
# Generates CURRENT_STATUS.md so Claude always knows what still needs work
# Run this before starting a development session or periodically during autonomous mode
# Version: 1.0
# Date: December 2025

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATUS_FILE="$PROJECT_ROOT/CURRENT_STATUS.md"
TODO_FILE="$PROJECT_ROOT/TODO.md"
BUGS_FILE="$PROJECT_ROOT/BUGS.md"
PROGRESS_FILE="$PROJECT_ROOT/PROGRESS.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

# Count items in TODO.md
count_todos() {
    local status="$1"  # pending, completed, or all
    if [[ ! -f "$TODO_FILE" ]]; then
        echo "0"
        return
    fi

    case "$status" in
        pending)
            grep -c "^\- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0"
            ;;
        completed)
            grep -c "^\- \[x\]" "$TODO_FILE" 2>/dev/null || echo "0"
            ;;
        all)
            grep -c "^\- \[" "$TODO_FILE" 2>/dev/null || echo "0"
            ;;
    esac
}

# Count open bugs
count_open_bugs() {
    if [[ ! -f "$BUGS_FILE" ]]; then
        echo "0"
        return
    fi
    grep -c "Status.*Open\|Status.*In Progress" "$BUGS_FILE" 2>/dev/null || echo "0"
}

# Check build status
check_build_status() {
    # Check for Android
    if [[ -f "$PROJECT_ROOT/gradlew" ]]; then
        if [[ -d "$PROJECT_ROOT/app/build/outputs/apk" ]]; then
            echo "android:passing"
        else
            echo "android:unknown"
        fi
    fi

    # Check for iOS
    if ls "$PROJECT_ROOT"/*.xcodeproj &>/dev/null || ls "$PROJECT_ROOT/ios"/*.xcodeproj &>/dev/null; then
        if [[ -d "$HOME/Library/Developer/Xcode/DerivedData" ]]; then
            echo "ios:unknown"  # Would need more sophisticated check
        fi
    fi
}

# Check test status
check_test_status() {
    local status="unknown"

    # Check for recent test results
    if [[ -d "$PROJECT_ROOT/app/build/test-results" ]]; then
        local failures
        failures=$(find "$PROJECT_ROOT/app/build/test-results" -name "*.xml" -exec grep -l "failures=\"[1-9]" {} \; 2>/dev/null | wc -l)
        if [[ "$failures" -gt 0 ]]; then
            status="failing"
        else
            status="passing"
        fi
    fi

    echo "$status"
}

# Check UI test status
check_ui_test_status() {
    local status="not_run"
    local results_dir="$PROJECT_ROOT/ui-test-results"

    if [[ -d "$results_dir" ]]; then
        local latest_report
        latest_report=$(ls -t "$results_dir"/report_*.html 2>/dev/null | head -n1)
        if [[ -n "$latest_report" ]]; then
            if grep -q "Failed.*0" "$latest_report" 2>/dev/null; then
                status="passing"
            else
                status="failing"
            fi
        fi
    fi

    echo "$status"
}

# Get list of pending TODOs
get_pending_todos() {
    if [[ ! -f "$TODO_FILE" ]]; then
        return
    fi
    grep "^\- \[ \]" "$TODO_FILE" 2>/dev/null | head -10 | sed 's/^- \[ \] //'
}

# Get list of open bugs
get_open_bugs() {
    if [[ ! -f "$BUGS_FILE" ]]; then
        return
    fi
    grep -A1 "Status.*Open\|Status.*In Progress" "$BUGS_FILE" 2>/dev/null | grep -v "Status" | head -5
}

# Generate CURRENT_STATUS.md
generate_status() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    local pending_count
    pending_count=$(count_todos pending)

    local completed_count
    completed_count=$(count_todos completed)

    local open_bugs
    open_bugs=$(count_open_bugs)

    local test_status
    test_status=$(check_test_status)

    local ui_test_status
    ui_test_status=$(check_ui_test_status)

    # Determine overall status
    local overall_status="IN_PROGRESS"
    local continue_working="YES"

    if [[ "$pending_count" -eq 0 && "$open_bugs" -eq 0 ]]; then
        overall_status="COMPLETE"
        continue_working="NO - All tasks complete!"
    elif [[ "$test_status" == "failing" ]]; then
        overall_status="BLOCKED - Tests Failing"
        continue_working="YES - Fix failing tests"
    elif [[ "$ui_test_status" == "failing" ]]; then
        overall_status="BLOCKED - UI Tests Failing"
        continue_working="YES - Fix UI test failures"
    fi

    cat > "$STATUS_FILE" << EOF
# Current Development Status

**Generated:** $timestamp
**Overall Status:** $overall_status

---

## Completion Criteria Checklist

| Criteria | Status | Action Required |
|----------|--------|-----------------|
| All TODO items complete | $([ "$pending_count" -eq 0 ] && echo "✅ DONE" || echo "❌ $pending_count pending") | $([ "$pending_count" -gt 0 ] && echo "Complete remaining items" || echo "None") |
| Build passing | $(check_build_status | grep -q "passing" && echo "✅ PASSING" || echo "⚠️ Unknown") | Run build verification |
| Unit tests passing | $([ "$test_status" == "passing" ] && echo "✅ PASSING" || echo "⚠️ $test_status") | Run ./gradlew test |
| UI tests passing | $([ "$ui_test_status" == "passing" ] && echo "✅ PASSING" || echo "⚠️ $ui_test_status") | Run ./scripts/run-ui-tests.sh |
| No open bugs | $([ "$open_bugs" -eq 0 ] && echo "✅ NONE" || echo "❌ $open_bugs open") | Fix open bugs |

---

## Should Claude Keep Working?

**$continue_working**

EOF

    if [[ "$pending_count" -gt 0 ]]; then
        cat >> "$STATUS_FILE" << EOF
---

## Pending TODO Items ($pending_count remaining)

EOF
        get_pending_todos | while read -r item; do
            echo "- [ ] $item" >> "$STATUS_FILE"
        done
    fi

    if [[ "$open_bugs" -gt 0 ]]; then
        cat >> "$STATUS_FILE" << EOF

---

## Open Bugs ($open_bugs)

EOF
        get_open_bugs >> "$STATUS_FILE"
    fi

    cat >> "$STATUS_FILE" << EOF

---

## Next Actions

1. $([ "$pending_count" -gt 0 ] && echo "Work on top TODO item" || echo "All TODO items complete")
2. $([ "$test_status" != "passing" ] && echo "Run and fix unit tests" || echo "Unit tests passing")
3. $([ "$ui_test_status" != "passing" ] && echo "Run and fix UI tests" || echo "UI tests passing")
4. $([ "$open_bugs" -gt 0 ] && echo "Fix open bugs" || echo "No open bugs")

---

## Quick Commands

\`\`\`bash
# Build
./gradlew build                    # Android
xcodebuild build                   # iOS

# Test
./gradlew test                     # Unit tests
./scripts/run-ui-tests.sh          # UI tests

# Status
./scripts/orchestrate.sh           # Regenerate this file
\`\`\`

---

*This file is auto-generated. Do not edit manually.*
EOF

    log_success "Generated: $STATUS_FILE"
}

# Main
main() {
    log_info "Generating current status..."

    generate_status

    echo ""
    echo "=== Summary ==="
    echo "Pending TODOs: $(count_todos pending)"
    echo "Completed:     $(count_todos completed)"
    echo "Open Bugs:     $(count_open_bugs)"
    echo "Unit Tests:    $(check_test_status)"
    echo "UI Tests:      $(check_ui_test_status)"
    echo ""
}

main "$@"
