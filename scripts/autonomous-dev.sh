#!/bin/bash

# Autonomous Development Mode Script
# Runs Claude Code in an autonomous loop for continuous development
# Version: 1.0
# Date: December 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_mode() { echo -e "${MAGENTA}[MODE]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TODO_FILE="$PROJECT_ROOT/TODO.md"
PROGRESS_FILE="$PROJECT_ROOT/PROGRESS.md"
BUGS_FILE="$PROJECT_ROOT/BUGS.md"

# Session settings
MAX_CONSECUTIVE_ERRORS=3
SESSION_LOG="$PROJECT_ROOT/.autonomous-session.log"
ERROR_COUNT=0

show_usage() {
    cat << EOF
Autonomous Development Mode Script

Usage: $0 [OPTIONS] [mode]

MODES:
    develop     Continue development from TODO.md (default)
    feature     Implement a specific feature
    bugfix      Fix a specific bug
    test        Generate and run tests
    review      Review and refactor code

OPTIONS:
    -h, --help          Show this help message
    -m, --message MSG   Custom instruction for Claude
    -n, --iterations N  Maximum iterations (default: unlimited)
    --dry-run           Show what would be done without running
    --reset             Clear session state and start fresh

EXAMPLES:
    $0                              # Start autonomous development
    $0 develop                      # Explicitly start development mode
    $0 feature "Add user profile"   # Implement specific feature
    $0 bugfix "Login crash"         # Fix specific bug
    $0 -n 5 develop                 # Run for max 5 iterations
    $0 --reset                      # Clear session and restart

STOPPING:
    Press Ctrl+C at any time to stop autonomous mode.
    Claude will automatically stop when:
    - All TODO items are complete
    - $MAX_CONSECUTIVE_ERRORS consecutive errors occur
    - A blocking issue requires human input

EOF
    exit 0
}

# Check if Claude CLI is available
check_claude() {
    if ! command -v claude &>/dev/null; then
        log_error "Claude CLI not found"
        log_info "Install Claude Code: https://claude.ai/code"
        exit 1
    fi
    log_success "Claude CLI available"
}

# Count pending TODO items
count_pending_todos() {
    if [[ -f "$TODO_FILE" ]]; then
        grep -c "^\- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get the top TODO item
get_top_todo() {
    if [[ -f "$TODO_FILE" ]]; then
        grep "^\- \[ \]" "$TODO_FILE" 2>/dev/null | head -n1 | sed 's/^- \[ \] //'
    else
        echo ""
    fi
}

# Initialize session
init_session() {
    log_info "Initializing autonomous session..."

    # Create session log
    echo "=== Autonomous Development Session ===" > "$SESSION_LOG"
    echo "Started: $(date)" >> "$SESSION_LOG"
    echo "Project: $PROJECT_ROOT" >> "$SESSION_LOG"
    echo "" >> "$SESSION_LOG"

    # Ensure tracking files exist
    if [[ ! -f "$TODO_FILE" ]]; then
        log_warning "TODO.md not found, creating empty file"
        echo "# TODO Items" > "$TODO_FILE"
        echo "" >> "$TODO_FILE"
        echo "## High Priority" >> "$TODO_FILE"
        echo "" >> "$TODO_FILE"
        echo "## Medium Priority" >> "$TODO_FILE"
        echo "" >> "$TODO_FILE"
        echo "## Low Priority" >> "$TODO_FILE"
    fi

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo "# Development Progress" > "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi

    if [[ ! -f "$BUGS_FILE" ]]; then
        echo "# Bug Tracking" > "$BUGS_FILE"
        echo "" >> "$BUGS_FILE"
        echo "## Open Bugs" >> "$BUGS_FILE"
        echo "" >> "$BUGS_FILE"
        echo "## Fixed Bugs" >> "$BUGS_FILE"
    fi
}

# Build the autonomous development instruction
build_develop_instruction() {
    local top_todo
    top_todo=$(get_top_todo)

    cat << EOF
You are in AUTONOMOUS DEVELOPMENT MODE.

CRITICAL INSTRUCTION: Do NOT stop and wait for confirmation between tasks. Continue working through ALL TODO items until complete or blocked.

CURRENT STATE:
- Pending TODO items: $(count_pending_todos)
- Top TODO item: ${top_todo:-"None - check TODO.md"}
- Project root: $PROJECT_ROOT

YOUR WORKFLOW (execute continuously without pausing):

1. READ the top item from TODO.md
2. IMPLEMENT the feature/fix completely:
   - Write all necessary code
   - Follow existing patterns in the codebase
   - Add appropriate error handling
3. BUILD the project:
   - Android: ./gradlew build
   - iOS: xcodebuild -scheme [Scheme] build
   - If build fails, fix errors and retry (max 3 attempts)
4. TEST the changes:
   - Run unit tests: ./gradlew test (Android) or xcodebuild test (iOS)
   - Run UI tests if available: ./scripts/run-ui-tests.sh
   - If tests fail, fix and retry (max 3 attempts)
5. UPDATE documentation:
   - Add completion entry to PROGRESS.md with timestamp
   - Update README.md if user-facing changes
   - Update ARCHITECTURE.md if architectural changes
6. MARK COMPLETE:
   - Remove the completed item from TODO.md
   - Or change [ ] to [x]
7. COMMIT the changes:
   - git add .
   - git commit -m "[Feature/Fix] Description"
8. IMMEDIATELY start the next TODO item (step 1)

STOPPING CONDITIONS (only stop when):
- TODO.md has NO remaining items (all complete)
- You've failed the SAME issue 3+ times consecutively
- You encounter a BLOCKING ambiguity requiring human clarification
- A security-sensitive operation needs explicit approval

ERROR HANDLING:
- Build errors: Analyze, fix, rebuild (max 3 attempts)
- Test failures: Analyze, fix, retest (max 3 attempts)
- Unknown errors: Log to BUGS.md and continue to next item

DO NOT:
- Stop to ask "should I continue?"
- Wait for confirmation between tasks
- Stop after completing just one item
- Ask about task prioritization (follow TODO.md order)

START NOW: Begin with the top TODO item and keep working.
EOF
}

# Build instruction for feature mode
build_feature_instruction() {
    local feature_desc="$1"

    cat << EOF
You are in FEATURE DEVELOPMENT MODE.

TASK: Implement the following feature:
$feature_desc

WORKFLOW:
1. Analyze the feature requirements
2. Create a plan (update TODO.md with subtasks if complex)
3. Implement the feature
4. Write unit tests
5. Write UI tests if applicable
6. Build and verify all tests pass
7. Update documentation
8. Commit changes

Do NOT stop between steps. Complete the entire feature implementation.

If you encounter blockers, document them in BUGS.md and note what was completed in PROGRESS.md.
EOF
}

# Build instruction for bugfix mode
build_bugfix_instruction() {
    local bug_desc="$1"

    cat << EOF
You are in BUGFIX MODE.

BUG TO FIX: $bug_desc

WORKFLOW:
1. Analyze the bug description and reproduce if possible
2. Identify the root cause
3. Implement the fix
4. Write a test that would have caught this bug
5. Verify all existing tests still pass
6. Update BUGS.md (move to Fixed section)
7. Update PROGRESS.md with fix details
8. Commit with message: "[Fix] Description"

Do NOT stop until the bug is fixed and verified.
EOF
}

# Build instruction for test mode
build_test_instruction() {
    cat << EOF
You are in TEST GENERATION MODE.

TASK: Generate comprehensive tests for the codebase.

WORKFLOW:
1. Analyze existing code coverage
2. Identify untested code paths
3. Generate unit tests for business logic
4. Generate UI tests using Maestro (./scripts/generate-ui-tests.sh)
5. Run all tests and verify they pass
6. Update TODO.md with any issues found
7. Commit test additions

Focus on high-value tests that verify core functionality.
EOF
}

# Build instruction for review mode
build_review_instruction() {
    cat << EOF
You are in CODE REVIEW MODE.

TASK: Review and improve code quality.

WORKFLOW:
1. Check for code smells and anti-patterns
2. Identify refactoring opportunities
3. Verify documentation is up to date
4. Check test coverage
5. Look for security issues
6. Create TODO items for improvements found
7. Implement quick wins immediately
8. Document findings in PROGRESS.md

Do NOT make breaking changes without documenting them.
EOF
}

# Run Claude with instruction
run_claude() {
    local instruction="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "[$timestamp] Running Claude..." >> "$SESSION_LOG"

    # Run Claude with the instruction
    if claude --print "$instruction" 2>&1 | tee -a "$SESSION_LOG"; then
        ERROR_COUNT=0
        return 0
    else
        ((ERROR_COUNT++))
        echo "[$timestamp] Error occurred (count: $ERROR_COUNT)" >> "$SESSION_LOG"
        return 1
    fi
}

# Main development loop
run_develop_loop() {
    local max_iterations="${1:-0}"  # 0 = unlimited
    local iteration=0

    log_mode "Starting autonomous development loop..."
    echo ""

    while true; do
        ((iteration++))

        # Check max iterations
        if [[ $max_iterations -gt 0 && $iteration -gt $max_iterations ]]; then
            log_info "Reached maximum iterations ($max_iterations)"
            break
        fi

        # Check pending items
        local pending
        pending=$(count_pending_todos)

        if [[ "$pending" -eq 0 ]]; then
            log_success "All TODO items complete!"
            break
        fi

        log_info "Iteration $iteration - Pending items: $pending"
        log_info "Top item: $(get_top_todo)"
        echo ""

        # Build and run instruction
        local instruction
        instruction=$(build_develop_instruction)

        if ! run_claude "$instruction"; then
            if [[ $ERROR_COUNT -ge $MAX_CONSECUTIVE_ERRORS ]]; then
                log_error "Too many consecutive errors ($ERROR_COUNT). Stopping."
                break
            fi
            log_warning "Error occurred, retrying..."
            sleep 2
        fi

        # Small delay between iterations
        sleep 1
    done

    # Session summary
    echo ""
    echo "========================================"
    log_info "Autonomous Session Complete"
    echo "========================================"
    echo "Iterations: $iteration"
    echo "Remaining items: $(count_pending_todos)"
    echo "Session log: $SESSION_LOG"
    echo "========================================"
}

# Run single-task mode
run_single_mode() {
    local mode="$1"
    local description="$2"
    local instruction

    case "$mode" in
        feature)
            instruction=$(build_feature_instruction "$description")
            log_mode "Feature Mode: $description"
            ;;
        bugfix)
            instruction=$(build_bugfix_instruction "$description")
            log_mode "Bugfix Mode: $description"
            ;;
        test)
            instruction=$(build_test_instruction)
            log_mode "Test Generation Mode"
            ;;
        review)
            instruction=$(build_review_instruction)
            log_mode "Code Review Mode"
            ;;
        *)
            log_error "Unknown mode: $mode"
            exit 1
            ;;
    esac

    echo ""
    run_claude "$instruction"
}

# Parse arguments
MODE="develop"
CUSTOM_MESSAGE=""
MAX_ITERATIONS=0
DRY_RUN=false
DESCRIPTION=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                ;;
            -m|--message)
                CUSTOM_MESSAGE="$2"
                shift 2
                ;;
            -n|--iterations)
                MAX_ITERATIONS="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --reset)
                rm -f "$SESSION_LOG"
                log_info "Session state cleared"
                shift
                ;;
            develop|feature|bugfix|test|review)
                MODE="$1"
                shift
                # Capture description for feature/bugfix modes
                if [[ "$MODE" == "feature" || "$MODE" == "bugfix" ]] && [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    DESCRIPTION="$1"
                    shift
                fi
                ;;
            *)
                # Assume it's a description for the current mode
                if [[ -z "$DESCRIPTION" ]]; then
                    DESCRIPTION="$1"
                fi
                shift
                ;;
        esac
    done
}

# Main
main() {
    parse_args "$@"

    echo ""
    echo "========================================"
    echo "   Autonomous Development Mode"
    echo "========================================"
    echo ""

    check_claude
    init_session

    echo ""
    log_info "Mode: $MODE"
    log_info "Project: $PROJECT_ROOT"
    log_info "TODO items: $(count_pending_todos)"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN - showing instruction only"
        echo ""
        case "$MODE" in
            develop) build_develop_instruction ;;
            feature) build_feature_instruction "$DESCRIPTION" ;;
            bugfix) build_bugfix_instruction "$DESCRIPTION" ;;
            test) build_test_instruction ;;
            review) build_review_instruction ;;
        esac
        exit 0
    fi

    log_warning "Press Ctrl+C to stop at any time"
    echo ""
    sleep 2

    case "$MODE" in
        develop)
            run_develop_loop "$MAX_ITERATIONS"
            ;;
        feature|bugfix|test|review)
            run_single_mode "$MODE" "$DESCRIPTION"
            ;;
    esac
}

main "$@"
