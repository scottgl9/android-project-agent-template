#!/bin/bash

# Post-Tool Hook: Completion Criteria Check
# Runs after each tool execution to check if work should continue
# Place in .claude/hooks/ directory
# Version: 1.0

# This hook checks completion criteria and outputs signals for Claude

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TODO_FILE="$PROJECT_ROOT/TODO.md"
BUGS_FILE="$PROJECT_ROOT/BUGS.md"

# Count pending TODOs
pending_todos() {
    if [[ -f "$TODO_FILE" ]]; then
        grep -c "^\- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Count open bugs
open_bugs() {
    if [[ -f "$BUGS_FILE" ]]; then
        grep -c "Status.*Open" "$BUGS_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Check if build is needed
needs_build() {
    # Check if source files are newer than build outputs
    if [[ -f "$PROJECT_ROOT/gradlew" ]]; then
        local src_time
        local build_time
        src_time=$(find "$PROJECT_ROOT/app/src" -name "*.kt" -newer "$PROJECT_ROOT/app/build/outputs/apk/debug/app-debug.apk" 2>/dev/null | wc -l)
        if [[ "$src_time" -gt 0 ]]; then
            echo "yes"
            return
        fi
    fi
    echo "no"
}

# Main check
main() {
    local todos
    todos=$(pending_todos)

    local bugs
    bugs=$(open_bugs)

    # Output status for Claude to read
    if [[ "$todos" -gt 0 ]]; then
        echo "CONTINUE: $todos TODO items remaining. Keep working on next item."
    elif [[ "$bugs" -gt 0 ]]; then
        echo "CONTINUE: $bugs open bugs. Fix remaining bugs."
    else
        echo "COMPLETE: All TODO items and bugs resolved."
    fi
}

main
