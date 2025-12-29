# UI Test Plan

This document outlines the UI testing strategy for mobile application development.

## Overview

UI tests verify that the application's user interface functions correctly from the user's perspective. These tests use Maestro for cross-platform (Android and iOS) testing.

## Test Categories

### 1. Smoke Tests (P0 - Critical)

Quick tests that verify core functionality works. Run these after every build.

| Test ID | Test Name | Description | File |
|---------|-----------|-------------|------|
| SMOKE-001 | App Launch | App starts without crashing | `app_launch.yaml` |
| SMOKE-002 | Main Screen | Main content is visible | `app_launch.yaml` |

### 2. Authentication Tests (P0/P1)

Tests for login, logout, and session management.

| Test ID | Test Name | Description | Priority | File |
|---------|-----------|-------------|----------|------|
| AUTH-001 | Login Success | Valid credentials allow login | P0 | `login_flow.yaml` |
| AUTH-002 | Login Failure | Invalid credentials show error | P1 | `login_error.yaml` |
| AUTH-003 | Logout | User can log out | P1 | `logout_flow.yaml` |
| AUTH-004 | Session Persist | App remembers user | P2 | `session_flow.yaml` |

### 3. Navigation Tests (P1)

Tests for navigating between app screens.

| Test ID | Test Name | Description | File |
|---------|-----------|-------------|------|
| NAV-001 | Bottom Nav | Can use bottom navigation | `navigation_flow.yaml` |
| NAV-002 | Back Button | Back navigation works | `back_navigation.yaml` |
| NAV-003 | Deep Link | Deep links open correct screen | `deep_link.yaml` |

### 4. Feature Tests (P1/P2)

Tests for main application features. Add entries based on your PRD.

| Test ID | Test Name | Description | Priority | File |
|---------|-----------|-------------|----------|------|
| FEAT-001 | [Feature 1] | [Description] | P1 | `feature1.yaml` |
| FEAT-002 | [Feature 2] | [Description] | P1 | `feature2.yaml` |
| FEAT-003 | [Feature 3] | [Description] | P2 | `feature3.yaml` |

### 5. Form & Input Tests (P1)

Tests for data entry and validation.

| Test ID | Test Name | Description | File |
|---------|-----------|-------------|------|
| FORM-001 | Required Fields | Empty required fields show error | `form_validation.yaml` |
| FORM-002 | Email Validation | Invalid email shows error | `form_validation.yaml` |
| FORM-003 | Submit Success | Valid form submits | `form_submit.yaml` |

### 6. Error Handling Tests (P2)

Tests for graceful error handling.

| Test ID | Test Name | Description | File |
|---------|-----------|-------------|------|
| ERR-001 | Network Error | App handles offline | `offline_test.yaml` |
| ERR-002 | Invalid Data | Handles malformed data | `error_handling.yaml` |
| ERR-003 | Timeout | Handles slow responses | `timeout_test.yaml` |

## Test Execution

### Prerequisites

```bash
# Install Maestro
./scripts/install-ui-testing.sh

# Verify installation
./scripts/install-ui-testing.sh --verify
```

### Running Tests

```bash
# Run all tests
./scripts/run-ui-tests.sh android
./scripts/run-ui-tests.sh ios

# Run specific test
./scripts/run-ui-tests.sh -t login_flow.yaml android

# Run with retries on failure
./scripts/run-ui-tests.sh -r 3 android

# Continue on failure (run all tests)
./scripts/run-ui-tests.sh -c android
```

### Automated Testing

UI tests should run:
1. **After every successful build** - via `autonomous-dev.sh`
2. **Before every commit** - manual or hook
3. **In CI/CD pipeline** - GitHub Actions / similar

### Integration with Development Workflow

```bash
# Full workflow
./gradlew build && ./scripts/run-ui-tests.sh android

# Or use autonomous mode
./scripts/autonomous-dev.sh
```

## Completion Criteria

A feature is considered complete when:

- [ ] All associated UI tests pass
- [ ] No visual regressions
- [ ] Tests cover happy path and error cases
- [ ] Screenshots captured at key points
- [ ] Test results documented

## Writing New Tests

### 1. Identify Test Cases

From PRD or feature requirements, identify:
- Happy path (normal successful flow)
- Error paths (validation, network, etc.)
- Edge cases (empty states, long text, etc.)

### 2. Create Test File

```yaml
# test_name.yaml
# Description of what this test verifies
appId: com.example.myapp
---
- launchApp:
    clearState: true

# Test steps
- assertVisible: "Expected Screen"
- tapOn: "Action Button"
- assertVisible: "Expected Result"

- takeScreenshot: test_complete
```

### 3. Verify Test Works

```bash
./scripts/run-ui-tests.sh -t test_name.yaml android
```

### 4. Update This Document

Add the new test to the appropriate category above.

## Priority Definitions

| Priority | Description | When to Run |
|----------|-------------|-------------|
| P0 | Critical - App must work | Every build |
| P1 | High - Core features | Every commit |
| P2 | Medium - Secondary features | Daily/PR |
| P3 | Low - Edge cases | Weekly/Release |

## Test Results

Results are saved to `ui-test-results/`:
- JUnit XML reports for CI integration
- HTML reports for human review
- Screenshots on failure

## Troubleshooting

### Test Fails Intermittently

- Add `waitForAnimationToEnd` before assertions
- Increase timeout values
- Add retry logic: `./scripts/run-ui-tests.sh -r 3`

### Element Not Found

- Use regex patterns: `"Login|Sign In"`
- Check element is actually visible on screen
- Use `optional: true` for elements that may not exist

### Screenshots Not Captured

- Check write permissions to `ui-test-results/`
- Verify device/simulator is connected
- Check ADB/Simulator status

## Maintenance

- [ ] Review tests when UI changes
- [ ] Add tests for new features
- [ ] Remove tests for deprecated features
- [ ] Update selectors when element IDs change
- [ ] Keep this document current
