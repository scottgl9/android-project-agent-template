# UI Tests

This directory contains Maestro UI test flows for cross-platform testing.

## Test Files

| File | Description |
|------|-------------|
| `app_launch.yaml` | Verifies app launches successfully |
| `login_flow.yaml` | Tests user authentication flow |
| `navigation_flow.yaml` | Tests main app navigation |

## Running Tests

```bash
# Run all tests on Android
./scripts/run-ui-tests.sh android

# Run all tests on iOS
./scripts/run-ui-tests.sh ios

# Run specific test
./scripts/run-ui-tests.sh -t login_flow.yaml android

# List available tests
./scripts/run-ui-tests.sh --list
```

## Creating New Tests

1. Create a new `.yaml` file in this directory
2. Follow the Maestro syntax (see examples)
3. Update app ID to match your application
4. Run test to verify it works

### Test Template

```yaml
# Test Name
# Description of what this test verifies
appId: com.example.myapp
---
- launchApp:
    clearState: true

# Your test steps here
- assertVisible: "Expected Element"
- tapOn: "Button"
- inputText: "Test input"
- assertVisible: "Result"

- takeScreenshot: test_name
```

## Maestro Commands Reference

| Command | Description |
|---------|-------------|
| `launchApp` | Launch the application |
| `tapOn` | Tap on an element |
| `inputText` | Type text |
| `assertVisible` | Verify element is visible |
| `assertNotVisible` | Verify element is not visible |
| `scroll` | Scroll in a direction |
| `swipe` | Swipe gesture |
| `hideKeyboard` | Dismiss keyboard |
| `takeScreenshot` | Capture screenshot |
| `waitForAnimationToEnd` | Wait for animations |

## Directory Structure

```
ui-tests/
├── app_launch.yaml      # Basic launch test
├── login_flow.yaml      # Authentication test
├── navigation_flow.yaml # Navigation test
├── shared/              # Reusable test components
│   └── login_helper.yaml
└── README.md            # This file
```

## Tips

1. Use regex patterns for flexible matching: `"Login|Sign In"`
2. Set appropriate timeouts for slow operations
3. Use `optional: true` for elements that may not exist
4. Take screenshots at key points for debugging
5. Use `clearState: true` for fresh start tests
