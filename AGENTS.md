# AI Agent Development Guide

## Which Guide to Use

**If you are:**
- **Claude Code / Claude AI** → Use `CLAUDE.md`
- **GitHub Copilot / Codex** → Use `CODEX.md`
- **Other AI Agent** → Use this document

## Overview
This document provides general instructions for AI agents to autonomously develop Android applications from a Product Requirements Document (PRD). Agent-specific guides (CLAUDE.md, CODEX.md) provide optimized workflows tailored to each agent's capabilities.

## Initial Setup

### 1. Environment Validation
When starting a new project from this template:
1. Run `./scripts/validate-android-environment.sh` to check Android development environment
2. If validation fails, run `./scripts/install-android-environment.sh`
3. Check for connected devices:
   ```bash
   adb devices
   ```
4. If real device is connected and authorized, use it for testing
5. If no device available and you need to test, optionally start emulator with `./scripts/run_emulator.sh`

### 2. PRD Processing
1. Read `PRD.md` thoroughly
2. Extract all features, requirements, and user stories
3. Break down into implementable tasks
4. Populate `TODO.md` with all tasks in priority order

## Development Workflow

### Core Loop
Follow this cycle for each task:

```
1. Read top item from TODO.md
2. Implement the feature
3. Create unit tests for the feature
4. Build the project
5. Run all unit tests
6. If tests pass:
   - Remove item from TODO.md
   - Update PROGRESS.md with completion details
   - Update README.md if user-facing changes
   - Update ARCHITECTURE.md if architectural changes
   - Commit changes with descriptive message
   - Push to repository
7. If tests fail:
   - Debug and fix issues
   - Repeat from step 4
8. Move to next TODO item
```

### Task Implementation Guidelines

#### Before Starting a Task
- [ ] Ensure previous task is fully committed and pushed
- [ ] Read the task requirements carefully
- [ ] Identify affected files and components
- [ ] Check ARCHITECTURE.md for design patterns to follow

#### During Implementation
- [ ] Follow Android best practices and Material Design guidelines
- [ ] Write clean, maintainable, well-documented code
- [ ] Use Kotlin unless specified otherwise
- [ ] Follow MVVM or MVI architecture patterns
- [ ] Implement dependency injection where appropriate
- [ ] **IMPORTANT: Add all new user-facing strings to `app/src/main/res/values/strings.xml` for translation support**
  - UI strings (button labels, titles, error messages) → `strings.xml`
  - Domain logic strings (LLM prompts, internal errors, logs) → Keep in code
  - Use `stringResource(R.string.your_string_id)` in Composables
  - Use `context.getString(R.string.your_string_id)` in Activities/Fragments
  - Never hardcode user-facing text in Kotlin code

#### Testing Requirements
- [ ] Create unit tests for all business logic
- [ ] Create UI tests for user-facing features
- [ ] Ensure test coverage is meaningful
- [ ] Tests should be independent and repeatable
- [ ] Mock external dependencies appropriately

#### Build Verification
```bash
./gradlew clean build
./gradlew test

# Check for connected devices
adb devices

# Install on connected device (real device or emulator)
./gradlew installDebug

# Run instrumented tests on connected device
./gradlew connectedAndroidTest
```

#### Commit Guidelines
- Use clear, descriptive commit messages
- Format: `[Feature/Fix/Test] Brief description`
- Example: `[Feature] Add user authentication with Firebase`
- Include issue references if applicable

## File Management

### TODO.md
- Keep tasks in priority order (top = highest priority)
- Each task should be actionable and specific
- Format:
  ```markdown
  ## TODO Items
  
  ### High Priority
  - [ ] Task description with acceptance criteria
  
  ### Medium Priority
  - [ ] Task description with acceptance criteria
  
  ### Low Priority
  - [ ] Task description with acceptance criteria
  ```

### PROGRESS.md
- Log completed tasks with timestamps
- Include brief description of what was implemented
- Note any challenges or decisions made
- Format:
  ```markdown
  ## Progress Log
  
  ### [Date] - Feature Name
  - Implemented: Description
  - Tests Added: Description
  - Notes: Any important decisions or issues
  ```

### BUGS.md
- Track all discovered bugs
- Include reproduction steps
- Mark priority level
- Update status as bugs are fixed
- Format:
  ```markdown
  ## Open Bugs
  
  ### [Priority] Bug Title
  - **Status**: Open/In Progress/Fixed
  - **Found**: Date
  - **Description**: What's wrong
  - **Reproduction**: Steps to reproduce
  - **Expected**: What should happen
  - **Actual**: What actually happens
  ```

### README.md
- Keep updated with project overview
- Document setup instructions
- List key features as they're implemented
- Include usage examples

### ARCHITECTURE.md
- Document architectural decisions
- Describe module structure
- Explain design patterns used
- Include diagrams where helpful

## Error Handling

### Build Failures
1. Read error messages carefully
2. Check dependencies in `build.gradle`
3. Verify Android SDK versions
4. Check for syntax errors
5. Ensure all resources are properly defined
6. If persistent, add to BUGS.md with details

### Test Failures
1. Analyze test output
2. Check test assumptions
3. Verify mock configurations
4. Ensure test data is correct
5. Debug step by step
6. Fix root cause, not symptoms

### Runtime Issues
1. Check LogCat for errors
2. Verify permissions in AndroidManifest.xml
3. Check resource availability
4. Validate network connections
5. Ensure proper lifecycle handling

## Adding New TODO Items

When discovering additional work during implementation:
1. Add to bottom of TODO.md under appropriate priority
2. Include context about why it's needed
3. Don't interrupt current task flow
4. Update after current task commits

## Quality Standards

### Code Quality
- Follow Kotlin coding conventions
- Use meaningful variable and function names
- Keep functions small and focused
- Avoid code duplication
- Comment complex logic

### Architecture Quality
- Separate concerns appropriately
- Use interfaces for flexibility
- Follow SOLID principles
- Keep coupling loose
- Make cohesion high

### Test Quality
- Tests should be fast
- Tests should be deterministic
- Tests should be isolated
- Tests should be readable
- Tests should test behavior, not implementation

## Continuous Improvement

After every 5 completed tasks:
1. Review code quality
2. Check for refactoring opportunities
3. Update documentation
4. Review test coverage
5. Consider architectural improvements

## Emergency Procedures

### Project Won't Build
1. Revert last commit
2. Verify environment with validation script
3. Clean and rebuild
4. Check for missing dependencies
5. Document issue in BUGS.md

### Lost Context
1. Read PROGRESS.md for recent work
2. Check TODO.md for current priorities
3. Review ARCHITECTURE.md for design
4. Read recent commits
5. Continue from top of TODO.md

## Success Criteria

A task is complete when:
- [ ] Feature works as specified in PRD
- [ ] All unit tests pass
- [ ] Code builds without errors or warnings
- [ ] Documentation is updated
- [ ] Changes are committed and pushed
- [ ] TODO.md is updated
- [ ] PROGRESS.md is updated

## Agent-Specific Notes

### For All Agents
- Work autonomously but document decisions
- Prioritize working software over perfect code
- Iterate and improve continuously
- Ask for clarification only when PRD is ambiguous
- Keep human developer informed through documentation

### Development Velocity
- Aim for steady, sustainable progress
- Don't skip testing to go faster
- Don't accumulate technical debt
- Refactor as you go when needed
- Balance speed with quality

## Device Management

### Detecting Available Devices
Before testing, always check for available devices:
```bash
adb devices
```

### Device Priority
1. **Real Device (Authorized)** - Preferred for testing
   - Faster than emulator
   - Real-world conditions
   - Better performance metrics
2. **Emulator** - Optional fallback
   - Only needed if no real device available
   - Can be started with `./scripts/run_emulator.sh` if required

### Installing on Device
```bash
# Install debug build
./gradlew installDebug

# Install on specific device (if multiple connected)
adb -s <device-id> install app/build/outputs/apk/debug/app-debug.apk
```

### Running Tests on Device
```bash
# Run all instrumented tests
./gradlew connectedAndroidTest

# Run on specific device
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.deviceId=<device-id>
```

### Troubleshooting Device Connection
- If device shows as "unauthorized", check device screen for authorization prompt
- If device not detected, try `adb kill-server && adb start-server`
- Ensure USB debugging is enabled on device
- Check USB cable and port

## Getting Started Checklist

- [ ] Validate Android environment
- [ ] Check for connected devices via `adb devices`
- [ ] Authorize device if needed
- [ ] Read PRD.md completely
- [ ] Create initial TODO.md from PRD
- [ ] Initialize PROGRESS.md
- [ ] Initialize BUGS.md
- [ ] Review ARCHITECTURE.md (if exists)
- [ ] Set up version control
- [ ] Begin first TODO item

---

**Remember**: The goal is working software that meets the PRD requirements. Stay focused, test thoroughly, and document as you go.
