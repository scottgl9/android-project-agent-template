# Claude Code Development Guide

> **👉 FOR CLAUDE USE ONLY**
> If you are GitHub Copilot or Codex, use `CODEX.md` instead.
> If you are another AI agent, use `AGENTS.md`.

## Introduction
This guide is specifically tailored for Claude (Anthropic's AI assistant) working on Android and iOS mobile application development. Follow these instructions to autonomously develop mobile apps from the PRD.

**Do not refer to other guide documents.** All necessary information for Claude is contained in this file.

## Platform Support

| Development Host | Android | iOS |
|-----------------|---------|-----|
| macOS (Intel/ARM) | ✅ Full support | ✅ Full support |
| Linux (x86_64/ARM64) | ✅ Full support | ❌ Not supported |

> **Note**: iOS development requires macOS due to Xcode requirements. See `PLATFORM_GUIDE.md` for comprehensive cross-platform guidance.

## Claude-Specific Capabilities

### Strengths to Leverage
- **Long context understanding**: Use this to maintain awareness of entire codebase
- **Careful reasoning**: Think through architectural decisions thoroughly
- **Error analysis**: Carefully analyze build and test failures
- **Documentation**: Generate comprehensive, clear documentation
- **Code review**: Self-review code before committing

### Working Mode
- Operate in extended thinking mode for complex tasks
- Break down large features into manageable subtasks
- Maintain context across the entire development session
- Proactively identify potential issues

## Autonomous Development Mode

When working autonomously, follow this structured approach to continue working without requiring "keep working" prompts.

### Completion Criteria Checklist

**DO NOT STOP until ALL of these are met:**

- [ ] All TODO.md items are complete (no `- [ ]` remaining)
- [ ] Build passes without errors
- [ ] All unit tests pass
- [ ] All UI tests pass (run `./scripts/run-ui-tests.sh`)
- [ ] No open bugs in BUGS.md
- [ ] PROGRESS.md is updated
- [ ] Changes are committed

### Autonomous Development Loop

```
┌─────────────────────────────────────────────────────────┐
│ 1. Check CURRENT_STATUS.md (or run ./scripts/orchestrate.sh) │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Read top TODO item from TODO.md                      │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 3. IMPLEMENT completely (all code, tests, docs)         │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 4. BUILD: ./gradlew build (Android) or xcodebuild (iOS) │
│    If fails → fix and retry (max 3 attempts)            │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 5. TEST: ./gradlew test && ./scripts/run-ui-tests.sh    │
│    If fails → fix and retry (max 3 attempts)            │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 6. UPDATE: PROGRESS.md, README.md, ARCHITECTURE.md      │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 7. COMMIT: git add . && git commit -m "[Type] desc"     │
└─────────────────────────────────┬───────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────┐
│ 8. Mark complete in TODO.md → IMMEDIATELY go to step 1  │
└─────────────────────────────────────────────────────────┘
```

### When to Stop (and ONLY when)

1. **All TODO items complete** - No `- [ ]` items remaining
2. **Blocking ambiguity** - PRD is unclear and needs human clarification
3. **Repeated failures** - Same error 3+ consecutive times
4. **Security operation** - Needs explicit human approval

### UI Testing Integration

After EVERY successful build, run UI tests:

```bash
# Generate status check
./scripts/orchestrate.sh

# Run UI tests
./scripts/run-ui-tests.sh android   # or ios

# If tests fail, fix and retest before continuing
```

### Status Tracking

Use these files to track progress:

| File | Purpose | Update When |
|------|---------|-------------|
| `TODO.md` | Pending tasks | Add/remove tasks |
| `PROGRESS.md` | Completed work | After each task |
| `BUGS.md` | Issues found | When bugs discovered |
| `CURRENT_STATUS.md` | Auto-generated status | Run orchestrate.sh |

### Quick Commands for Autonomous Mode

```bash
# Start autonomous development
./scripts/autonomous-dev.sh

# Generate current status
./scripts/orchestrate.sh

# Run all tests
./gradlew test && ./scripts/run-ui-tests.sh android
```

## Project Initialization

### Step 1: Environment Check

#### For Android (macOS or Linux):
```bash
# Run validation script
./scripts/validate-android-environment.sh

# If validation fails, run installer
./scripts/install-android-environment.sh

# Check for connected Android devices
adb devices

# If real device is connected and authorized, use it for testing
# If no device and testing is needed, optionally start emulator:
# ./scripts/run_emulator.sh
```

#### For iOS (macOS Only):
```bash
# Run validation script
./scripts/validate-ios-environment.sh

# If validation fails, run installer
./scripts/install-ios-environment.sh

# Check for available simulators
xcrun simctl list devices available

# Run on simulator
./scripts/run_simulator.sh MyAppScheme
```

### Step 2: Parse PRD
1. Open and read `PRD.md` in its entirety
2. Identify all features, user stories, and requirements
3. Note any technical constraints or preferences
4. Clarify any ambiguities (if human developer is available)

### Step 3: Create Task List
1. Break down PRD into discrete, testable tasks
2. Order by dependencies (foundation first)
3. Group related tasks
4. Estimate complexity for each task
5. Write to `TODO.md` with this structure:

```markdown
## TODO Items

### Foundation Tasks
- [ ] Set up project structure and base architecture
- [ ] Configure build system and dependencies
- [ ] Set up dependency injection framework

### Feature Tasks
- [ ] [Feature Name]: Brief description
  - Acceptance criteria: What defines done
  - Dependencies: What must be done first
  - Testing: What tests are needed

### Polish Tasks
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Documentation completion
```

## Development Cycle

### For Each TODO Item

#### Phase 1: Understanding
1. Read the task completely
2. Review related code in codebase
3. Check ARCHITECTURE.md for patterns to follow
4. Identify files that need changes
5. Plan the implementation approach

#### Phase 2: Implementation
1. Create or modify necessary files
2. Follow Android and Kotlin best practices:
   - Use Kotlin coroutines for async operations
   - Implement MVVM or MVI architecture
   - Use LiveData or StateFlow for reactive data
   - Follow Material Design guidelines
   - Use proper dependency injection
3. Add inline documentation for complex logic
4. Ensure error handling is robust

#### Phase 3: Testing
1. Create unit tests for business logic:
   ```kotlin
   @Test
   fun `test description in backticks`() {
       // Given
       val input = setupTestData()
       
       // When
       val result = functionUnderTest(input)
       
       // Then
       assertEquals(expected, result)
   }
   ```

2. Create UI tests for user-facing features:
   ```kotlin
   @Test
   fun testUserInteraction() {
       onView(withId(R.id.button))
           .perform(click())
       onView(withId(R.id.result))
           .check(matches(withText("Expected")))
   }
   ```

3. Consider edge cases and error scenarios

#### Phase 4: Verification

**For Android:**
```bash
# Clean build
./gradlew clean

# Build project
./gradlew build

# Run unit tests
./gradlew test

# Check for connected devices (real device or emulator)
adb devices

# Install on device
./gradlew installDebug

# Run instrumented tests on connected device
./gradlew connectedAndroidTest

# Check for lint issues
./gradlew lint
```

**For iOS (macOS Only):**
```bash
# Clean build
xcodebuild clean -scheme MyScheme

# Build project
xcodebuild -scheme MyScheme -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -scheme MyScheme -destination 'platform=iOS Simulator,name=iPhone 15'

# Lint check
swiftlint lint

# Install on simulator
xcrun simctl install booted /path/to/MyApp.app
```

#### Phase 5: Documentation
1. Update `PROGRESS.md`:
   ```markdown
   ### [YYYY-MM-DD HH:MM] - Feature Name
   - **Implemented**: What was built
   - **Files Changed**: List of modified files
   - **Tests Added**: Description of test coverage
   - **Decisions Made**: Any important architectural decisions
   - **Challenges**: Any issues encountered and how resolved
   ```

2. Update `README.md` if:
   - New feature is user-facing
   - Setup instructions changed
   - New dependencies were added

3. Update `ARCHITECTURE.md` if:
   - New modules were created
   - Architectural patterns were established
   - Major design decisions were made

#### Phase 6: Commit and Push
```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "[Feature] Description of what was implemented

- Bullet points of key changes
- Reference to PRD section if applicable
- Note any breaking changes"

# Push to repository
git push origin main
```

#### Phase 7: Cleanup
1. Remove completed item from `TODO.md`
2. If new tasks were discovered, add to bottom of `TODO.md`
3. If bugs were found, document in `BUGS.md`

## Claude-Specific Best Practices

### Thinking Process
Before implementing, explicitly reason through:
1. **What** needs to be done
2. **Why** this approach is best
3. **How** it integrates with existing code
4. **What** could go wrong
5. **How** to test it properly

### Code Generation
- Generate complete, runnable code
- Include all necessary imports
- Add KDoc comments for public APIs
- Consider null safety
- Use meaningful variable names
- Prefer immutability when possible

### Error Handling
When build or tests fail:
1. Read the complete error message
2. Identify the root cause (not just symptoms)
3. Check related files for context
4. Fix the issue properly
5. Verify the fix with tests
6. Document if it's a recurring pattern

### Context Management
- Keep track of overall project state
- Maintain awareness of file dependencies
- Remember architectural decisions made
- Track patterns established in the codebase
- Update mental model as code evolves

### Self-Review Checklist
Before committing, verify:
- [ ] Code compiles without errors
- [ ] All tests pass
- [ ] No new warnings introduced
- [ ] Code follows project conventions
- [ ] Documentation is updated
- [ ] No debug code left in
- [ ] Resource files are properly organized
- [ ] Strings are in resources (not hardcoded)
- [ ] Proper error handling exists
- [ ] Edge cases are handled

## Platform-Specific Development

### Android Development

#### Device Testing Strategy

#### Always Check for Devices First
```bash
adb devices
```

#### Device Priority
1. **Real Android Device** (if connected and authorized)
   - Provides real-world performance
   - Better for sensor testing (GPS, accelerometer, etc.)
   - More accurate battery and network behavior
   - Faster than emulator

2. **Android Emulator** (optional fallback)
   - Only needed if no physical device available
   - Can be started with `./scripts/run_emulator.sh` if required
   - Not mandatory for development if real device is used

#### Working with Real Devices
```bash
# Check device authorization status
adb devices
# Should show: <device-id>    device
# If shows "unauthorized", check device screen for prompt

# Install app on device
./gradlew installDebug

# Run tests on device
./gradlew connectedAndroidTest

# View logs from device
adb logcat | grep "YourAppTag"

# Clear app data for fresh test
adb shell pm clear com.your.package

# Uninstall app
adb uninstall com.your.package
```

#### Multiple Devices
If multiple devices are connected:
```bash
# List all devices
adb devices

# Target specific device
adb -s <device-id> install app/build/outputs/apk/debug/app-debug.apk
adb -s <device-id> shell am start -n com.your.package/.MainActivity

# Run tests on specific device
GRADLE_OPTS="-Pandroid.testInstrumentationRunnerArguments.deviceId=<device-id>" ./gradlew connectedAndroidTest
```

#### Device Troubleshooting
- **Device not detected**: 
  - Restart ADB: `adb kill-server && adb start-server`
  - Check USB cable and port
  - Enable USB debugging in Developer Options
  - Try different USB mode (File Transfer/PTP)

- **Unauthorized device**:
  - Check device screen for authorization prompt
  - Accept "Always allow from this computer"
  - Revoke and retry: `adb kill-server && adb start-server`

- **Installation failed**:
  - Check storage space on device
  - Uninstall previous version: `adb uninstall com.your.package`
  - Check for signature conflicts

### Project Structure
Follow this standard Android structure:
```
app/
├── src/
│   ├── main/
│   │   ├── java/com/package/
│   │   │   ├── ui/          # Activities, Fragments, Composables
│   │   │   ├── viewmodel/   # ViewModels
│   │   │   ├── data/        # Repository, Data Sources
│   │   │   ├── domain/      # Use Cases, Business Logic
│   │   │   ├── model/       # Data Models
│   │   │   ├── di/          # Dependency Injection
│   │   │   └── util/        # Utilities
│   │   ├── res/             # Resources
│   │   └── AndroidManifest.xml
│   ├── test/                # Unit Tests
│   └── androidTest/         # Instrumented Tests
└── build.gradle
```

### Common Dependencies
Include as needed:
```gradle
// Core Android
implementation 'androidx.core:core-ktx:1.12.0'
implementation 'androidx.appcompat:appcompat:1.6.1'

// UI
implementation 'com.google.android.material:material:1.11.0'
implementation 'androidx.constraintlayout:constraintlayout:2.1.4'

// Lifecycle
implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0'
implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.7.0'

// Coroutines
implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'

// Dependency Injection
implementation 'com.google.dagger:hilt-android:2.48'
kapt 'com.google.dagger:hilt-compiler:2.48'

// Testing
testImplementation 'junit:junit:4.13.2'
testImplementation 'org.mockito:mockito-core:5.7.0'
androidTestImplementation 'androidx.test.ext:junit:1.1.5'
androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
```

### Architectural Patterns

#### MVVM Pattern
```kotlin
// Model
data class User(val id: String, val name: String)

// Repository
class UserRepository {
    suspend fun getUser(id: String): Result<User> { ... }
}

// ViewModel
class UserViewModel(
    private val repository: UserRepository
) : ViewModel() {
    private val _user = MutableLiveData<User>()
    val user: LiveData<User> = _user
    
    fun loadUser(id: String) {
        viewModelScope.launch {
            repository.getUser(id)
                .onSuccess { _user.value = it }
                .onFailure { /* Handle error */ }
        }
    }
}

// View (Activity/Fragment)
class UserActivity : AppCompatActivity() {
    private val viewModel: UserViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.user.observe(this) { user ->
            // Update UI
        }
    }
}
```

## Handling Complex Scenarios

### When Requirements are Unclear
1. Document assumptions in code comments
2. Implement most reasonable interpretation
3. Add note in PROGRESS.md about the decision
4. Flag for human review if critical

### When Tests Fail Repeatedly
1. Add issue to BUGS.md with full details
2. Create minimal reproduction case
3. Research the error pattern
4. If blocking, mark TODO item as blocked
5. Move to next unblocked item
6. Return to blocked item later

### When Architecture Needs Changes
1. Document current pain points
2. Propose solution in ARCHITECTURE.md
3. Create refactoring task in TODO.md
4. Implement gradually without breaking existing features

## Continuous Quality Assurance

### After Every 3 Tasks
- Review code for duplication
- Check for refactoring opportunities
- Ensure tests are maintainable
- Verify documentation is current

### Weekly (or every 10 tasks)
- Run full lint check
- Review test coverage
- Update architectural diagrams
- Clean up unused code
- Optimize imports

## Bug Management

### When You Discover a Bug
Add to `BUGS.md`:
```markdown
## Open Bugs

### [High/Medium/Low] Bug Title
- **Status**: Open
- **Found**: YYYY-MM-DD
- **Component**: Which part of app
- **Description**: Clear description
- **Reproduction**:
  1. Step one
  2. Step two
  3. Step three
- **Expected**: What should happen
- **Actual**: What actually happens
- **Stack Trace**: If applicable
- **Notes**: Any additional context
```

### When You Fix a Bug
1. Move from "Open Bugs" to "Fixed Bugs" section
2. Add fix date and description
3. Reference commit hash
4. Note any related changes needed

## Communication Protocol

### In PROGRESS.md
Be verbose and detailed:
- Explain what you did and why
- Document decisions and trade-offs
- Note any concerns or future considerations
- Provide context for next developer (human or AI)

### In Code Comments
Be concise but clear:
- Explain non-obvious logic
- Document assumptions
- Note TODOs for future improvements
- Reference external resources when relevant

### In Commit Messages
Be descriptive:
```
[Category] Short summary (50 chars or less)

More detailed explanatory text, if necessary. Wrap it to
about 72 characters. The blank line separating the summary
from the body is critical.

- Bullet points are okay
- Use imperative mood: "Add feature" not "Added feature"
- Reference issues if applicable: "Fixes #123"
```

## Success Metrics

Track these informally in PROGRESS.md:
- Tasks completed per session
- Build success rate (aim for >95%)
- Test pass rate (aim for 100%)
- Bugs introduced vs fixed
- Documentation completeness

## Final Notes

### Remember
- **Quality over speed**: Working software is the goal
- **Test thoroughly**: Tests prevent regression
- **Document decisions**: Help future developers (including yourself)
- **Stay focused**: One task at a time, top of TODO.md
- **Be consistent**: Follow established patterns

### When in Doubt
1. Check existing code for patterns
2. Refer to ARCHITECTURE.md
3. Follow Android best practices
4. Document your decision
5. Proceed with confidence

### iOS Development (macOS Only)

#### Project Structure
Follow this standard iOS structure:
```
ios/
├── MyApp.xcodeproj/         # Xcode project
├── MyApp/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Views/               # SwiftUI or UIKit views
│   ├── ViewModels/          # ViewModels
│   ├── Models/              # Data models
│   ├── Services/            # Network, data services
│   ├── Utilities/           # Helper functions
│   ├── Resources/           # Assets, strings
│   │   ├── Assets.xcassets
│   │   └── Localizable.strings
│   └── Info.plist
├── MyAppTests/              # Unit tests
└── MyAppUITests/            # UI tests
```

#### Common Dependencies (Swift Package Manager)
```swift
// In Package.swift or Xcode project dependencies
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.0.0"),
]
```

#### Build Commands
```bash
# Build for simulator
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for distribution
xcodebuild archive -scheme MyApp -archivePath build/MyApp.xcarchive

# Install on simulator
xcrun simctl install booted /path/to/MyApp.app

# Launch on simulator
xcrun simctl launch booted com.example.MyApp
```

---

**You've got this, Claude!** Follow this guide, stay systematic, and you'll build great mobile applications for both Android and iOS. Start with the top TODO item and work your way down.

For detailed cross-platform guidance, see `PLATFORM_GUIDE.md`.
