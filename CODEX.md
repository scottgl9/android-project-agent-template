# Codex Development Guide

> **👉 FOR GITHUB COPILOT / CODEX USE ONLY**
> If you are Claude or Claude Code, use `CLAUDE.md` instead.
> If you are another AI agent, use `AGENTS.md`.

## Introduction
This guide is specifically designed for GitHub Copilot / Codex to autonomously develop Android applications from a Product Requirements Document (PRD). Follow these instructions systematically to build high-quality Android apps.

**Do not refer to other guide documents.** All necessary information for Codex/Copilot is contained in this file.

## Quick Start

### Initial Setup Sequence
```bash
# 1. Validate environment
./scripts/validate-android-environment.sh

# 2. Install if needed
./scripts/install-android-environment.sh

# 3. Check for connected devices
adb devices

# 4. If real device connected and authorized, you're ready!
# 5. If no device and testing needed, optionally start emulator:
#    ./scripts/run_emulator.sh
```

### Project Initialization
1. **Read PRD**: Open `PRD.md` and understand all requirements
2. **Create TODO List**: Parse PRD into actionable tasks in `TODO.md`
3. **Initialize Tracking**: Create `PROGRESS.md` and `BUGS.md`
4. **Start Development**: Begin with first TODO item

## Core Development Loop

```
┌─────────────────────────────────────────┐
│ 1. Read top TODO item                   │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 2. Implement feature                    │
│    - Write code                         │
│    - Follow Android best practices      │
│    - Use Kotlin conventions             │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 3. Create tests                         │
│    - Unit tests for logic               │
│    - UI tests for features              │
│    - Ensure good coverage               │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 4. Build and test                       │
│    ./gradlew clean build test           │
└───────────┬─────────────────────────────┘
            ↓
         [Pass?]
            │
    ┌───────┴───────┐
   Yes              No
    │                │
    ↓                ↓
┌────────┐      ┌────────┐
│Continue│      │  Fix   │
└───┬────┘      └───┬────┘
    │               │
    │               └──────┐
    ↓                      ↓
┌─────────────────────────────────────────┐
│ 5. Update documentation                 │
│    - PROGRESS.md                        │
│    - README.md (if needed)              │
│    - ARCHITECTURE.md (if needed)        │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 6. Commit and push                      │
│    git commit -m "[Type] Description"   │
│    git push origin main                 │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 7. Remove from TODO, add to PROGRESS    │
└───────────┬─────────────────────────────┘
            ↓
┌─────────────────────────────────────────┐
│ 8. Start next TODO item                 │
└─────────────────────────────────────────┘
```

## File Structure Standards

### TODO.md Format
```markdown
## TODO Items

### High Priority
- [ ] **[Feature Name]**: Description
  - **AC**: Acceptance criteria
  - **Files**: Estimated files to change
  - **Tests**: Test types needed

### Medium Priority
- [ ] **[Feature Name]**: Description

### Low Priority
- [ ] **[Feature Name]**: Description

### Discovered During Development
- [ ] **[Additional Task]**: Why it's needed
```

### PROGRESS.md Format
```markdown
## Development Progress

### [YYYY-MM-DD] Session Summary
- **Tasks Completed**: X
- **Tests Added**: Y
- **Bugs Fixed**: Z

#### Task: [Feature Name]
- **Completed**: YYYY-MM-DD HH:MM
- **Implementation**: Brief description
- **Files Modified**:
  - `path/to/file1.kt`
  - `path/to/file2.kt`
- **Tests Added**:
  - Unit tests: Description
  - UI tests: Description
- **Notes**: Any important decisions or considerations
- **Commit**: `abc123def`
```

### BUGS.md Format
```markdown
## Bug Tracking

### Open Bugs
#### [P0/P1/P2] Bug Title
- **ID**: BUG-001
- **Status**: Open/In Progress/Testing
- **Discovered**: YYYY-MM-DD
- **Component**: Feature/Module
- **Severity**: Critical/High/Medium/Low
- **Description**: What's wrong
- **Steps to Reproduce**:
  1. Step one
  2. Step two
  3. Observe error
- **Expected**: What should happen
- **Actual**: What happens instead
- **Logs**: Relevant error messages
- **Assigned**: (If applicable)

### Fixed Bugs
#### [P1] Bug Title
- **Fixed**: YYYY-MM-DD
- **Solution**: What was done
- **Commit**: `abc123def`
```

## Code Generation Guidelines

### Kotlin Best Practices
```kotlin
// 1. Use data classes for models
data class User(
    val id: String,
    val name: String,
    val email: String
)

// 2. Use sealed classes for states
sealed class UiState {
    object Loading : UiState()
    data class Success(val data: Any) : UiState()
    data class Error(val message: String) : UiState()
}

// 3. Use coroutines for async
class Repository {
    suspend fun fetchData(): Result<Data> = withContext(Dispatchers.IO) {
        try {
            Result.success(api.getData())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// 4. Use extensions for utilities
fun String.isValidEmail(): Boolean {
    return android.util.Patterns.EMAIL_ADDRESS.matcher(this).matches()
}

// 5. Use proper null safety
fun processUser(user: User?) {
    user?.let {
        println(it.name)
    } ?: println("No user")
}
```

### Android Architecture (MVVM)
```kotlin
// ViewModel
class MainViewModel(
    private val repository: Repository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<UiState>(UiState.Loading)
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
    
    fun loadData() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            repository.fetchData()
                .onSuccess { _uiState.value = UiState.Success(it) }
                .onFailure { _uiState.value = UiState.Error(it.message ?: "Unknown error") }
        }
    }
}

// Activity
class MainActivity : AppCompatActivity() {
    private val viewModel: MainViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        lifecycleScope.launch {
            viewModel.uiState.collect { state ->
                when (state) {
                    is UiState.Loading -> showLoading()
                    is UiState.Success -> showData(state.data)
                    is UiState.Error -> showError(state.message)
                }
            }
        }
        
        viewModel.loadData()
    }
}
```

### Testing Patterns
```kotlin
// Unit Test
class UserViewModelTest {
    
    private lateinit var viewModel: UserViewModel
    private lateinit var repository: FakeUserRepository
    
    @Before
    fun setup() {
        repository = FakeUserRepository()
        viewModel = UserViewModel(repository)
    }
    
    @Test
    fun `loadUser success updates state correctly`() = runTest {
        // Given
        val expectedUser = User("1", "John", "john@example.com")
        repository.setResponse(Result.success(expectedUser))
        
        // When
        viewModel.loadUser("1")
        
        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UiState.Success)
        assertEquals(expectedUser, (state as UiState.Success).data)
    }
    
    @Test
    fun `loadUser failure shows error state`() = runTest {
        // Given
        repository.setResponse(Result.failure(Exception("Network error")))
        
        // When
        viewModel.loadUser("1")
        
        // Then
        val state = viewModel.uiState.value
        assertTrue(state is UiState.Error)
    }
}

// UI Test
@RunWith(AndroidJUnit4::class)
class MainActivityTest {
    
    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)
    
    @Test
    fun clickButton_displaysResult() {
        onView(withId(R.id.button))
            .perform(click())
        
        onView(withId(R.id.textView))
            .check(matches(isDisplayed()))
            .check(matches(withText("Expected Result")))
    }
}
```

## Build Commands Reference

```bash
# Clean build
./gradlew clean

# Build debug
./gradlew assembleDebug

# Build release
./gradlew assembleRelease

# Run unit tests
./gradlew test

# Run unit tests with report
./gradlew test --info

# === Device/Emulator Commands ===

# Check connected devices
adb devices

# Install app on device
./gradlew installDebug

# Install on specific device (if multiple)
adb -s <device-id> install app/build/outputs/apk/debug/app-debug.apk

# Run instrumented tests on connected device
./gradlew connectedAndroidTest

# Run tests on specific device
GRADLE_OPTS="-Pandroid.testInstrumentationRunnerArguments.deviceId=<device-id>" ./gradlew connectedAndroidTest

# === ADB Utility Commands ===

# View device logs
adb logcat

# Filter logs by app
adb logcat | grep "com.your.package"

# Clear app data
adb shell pm clear com.your.package

# Uninstall app
adb uninstall com.your.package

# Take screenshot
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png

# === Other Commands ===

# Run specific test class
./gradlew test --tests UserViewModelTest

# Run lint checks
./gradlew lint

# Check dependencies
./gradlew dependencies

# Generate test coverage report
./gradlew jacocoTestReport
```

## Git Workflow

### Commit Message Conventions
```
[Category] Short description (imperative mood)

Longer explanation if needed. Wrap at 72 characters.

- Key change 1
- Key change 2
- Key change 3

Refs: PRD section X.Y
```

**Categories**:
- `[Feature]` - New feature implementation
- `[Fix]` - Bug fix
- `[Test]` - Adding or updating tests
- `[Refactor]` - Code refactoring
- `[Docs]` - Documentation updates
- `[Build]` - Build system changes
- `[Style]` - Code style/formatting

### Example Commits
```bash
git commit -m "[Feature] Add user authentication

Implemented Firebase Authentication with email/password.
Added login and registration screens with validation.

- Created AuthRepository for auth operations
- Added LoginViewModel and RegisterViewModel
- Implemented UI with Material Design
- Added unit tests for ViewModels

Refs: PRD section 3.1 - User Authentication"
```

## Error Handling Strategy

### Build Errors
1. **Read error carefully** - Don't skip details
2. **Check file locations** - Ensure all imports are correct
3. **Verify dependencies** - Check build.gradle
4. **Clean and rebuild** - `./gradlew clean build`
5. **Check resources** - Ensure XML is valid
6. **Document if recurring** - Add to BUGS.md

### Test Failures
1. **Analyze failure message** - What exactly failed?
2. **Check test assumptions** - Are mocks configured correctly?
3. **Debug locally** - Use print statements or debugger
4. **Fix root cause** - Not just the symptom
5. **Verify fix** - Run all tests again
6. **Commit with context** - Explain what was wrong

### Runtime Errors
1. **Check LogCat** - Read stack trace
2. **Verify permissions** - AndroidManifest.xml
3. **Check lifecycle** - Ensure proper Activity/Fragment lifecycle handling
4. **Validate data** - Null checks, bounds checks
5. **Add logging** - For future debugging

## Productivity Optimizations

### Parallel Work (When Possible)
- Generate multiple related files together
- Create test files alongside implementation
- Update multiple documentation files in one pass

### Context Loading
- Read related files before modifying
- Check existing patterns in codebase
- Review recent commits for context

### Quality Checks
Before each commit, verify:
- [ ] Code compiles
- [ ] Tests pass
- [ ] No warnings introduced
- [ ] Documentation updated
- [ ] Follows existing patterns
- [ ] Resources properly organized

## Advanced Scenarios

### Large Features
Break into smaller tasks:
```markdown
- [ ] **[Feature] User Profile - Phase 1: UI**
  - Create layouts and views
  
- [ ] **[Feature] User Profile - Phase 2: ViewModel**
  - Implement business logic
  
- [ ] **[Feature] User Profile - Phase 3: Integration**
  - Connect to backend
  
- [ ] **[Feature] User Profile - Phase 4: Polish**
  - Error handling, loading states
```

### Refactoring
1. Ensure tests exist first
2. Make small, incremental changes
3. Run tests after each change
4. Commit frequently
5. Document the refactoring reason

### Adding Dependencies
```gradle
// In app/build.gradle

dependencies {
    // Core
    implementation "androidx.core:core-ktx:1.12.0"
    
    // DI - Hilt
    implementation "com.google.dagger:hilt-android:2.48"
    kapt "com.google.dagger:hilt-compiler:2.48"
    
    // Network - Retrofit
    implementation "com.squareup.retrofit2:retrofit:2.9.0"
    implementation "com.squareup.retrofit2:converter-gson:2.9.0"
    
    // Image Loading - Coil
    implementation "io.coil-kt:coil:2.5.0"
    
    // Testing
    testImplementation "junit:junit:4.13.2"
    testImplementation "org.mockito.kotlin:mockito-kotlin:5.1.0"
    testImplementation "org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3"
}
```

## Documentation Updates

### When to Update README.md
- New feature is user-visible
- Setup steps changed
- New dependencies added
- API endpoints changed

### When to Update ARCHITECTURE.md
- New modules created
- Design patterns established
- Major architectural decisions
- Data flow diagrams needed

### Always Update PROGRESS.md
After every completed task, document:
- What was built
- How it was tested
- Any decisions made
- Challenges encountered

## Metrics to Track

In PROGRESS.md, optionally track:
```markdown
## Development Metrics

### Sprint 1 (YYYY-MM-DD to YYYY-MM-DD)
- **Tasks Completed**: 12
- **Lines of Code Added**: ~1,500
- **Tests Created**: 45
- **Build Success Rate**: 98%
- **Test Pass Rate**: 100%
- **Bugs Found**: 3
- **Bugs Fixed**: 3
```

## Emergency Procedures

### Complete Build Failure
```bash
# 1. Stash changes
git stash

# 2. Return to known good state
git checkout HEAD~1

# 3. Verify it builds
./gradlew clean build

# 4. Reapply changes incrementally
git stash pop

# 5. Fix issues one at a time
```

### Lost Context
1. Read `PROGRESS.md` for recent work
2. Check `git log` for recent commits
3. Review `TODO.md` for current priorities
4. Read `ARCHITECTURE.md` for design
5. Continue from top of TODO.md

## Success Checklist

Before marking a task complete:
- [ ] Feature works as specified
- [ ] Code builds without errors
- [ ] All tests pass (unit + UI)
- [ ] No lint warnings
- [ ] Code is documented
- [ ] Resources are organized
- [ ] No hardcoded strings
- [ ] Error handling in place
- [ ] PROGRESS.md updated
- [ ] README.md updated (if needed)
- [ ] ARCHITECTURE.md updated (if needed)
- [ ] Changes committed
- [ ] Changes pushed
- [ ] TODO.md updated

## Tips for Efficiency

1. **Read before writing** - Understand existing code
2. **Follow patterns** - Be consistent with codebase
3. **Test early** - Don't wait until the end
4. **Commit often** - Small, focused commits
5. **Document as you go** - Don't defer documentation
6. **Stay organized** - Keep TODO.md current
7. **One task at a time** - Focus on top of TODO.md
8. **Quality over speed** - Working software is the goal

---

## Device Testing Workflow

### Priority: Real Device > Emulator

Always prefer testing on a real device when available:

```bash
# 1. Check for devices
adb devices

# Expected output:
# List of devices attached
# ABC123456789    device         <- Real device (authorized)
# emulator-5554   device         <- Emulator

# 2. If real device is available and authorized, use it
./gradlew installDebug
./gradlew connectedAndroidTest

# 3. Manual testing on device
# - Launch app from device
# - Test user flows
# - Check performance
# - Verify UI on real screen
```

### Device Authorization

If device shows as "unauthorized":
1. Check device screen for authorization prompt
2. Tap "Always allow from this computer"
3. If not showing, try:
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### Testing Checklist

Before marking task complete:
- [ ] Unit tests pass: `./gradlew test`
- [ ] App installs on device: `./gradlew installDebug`
- [ ] Instrumented tests pass: `./gradlew connectedAndroidTest`
- [ ] Manual smoke test on device
- [ ] No crashes in logcat: `adb logcat`
- [ ] UI looks correct on device screen

### Device-Specific Testing Notes

**Benefits of Real Device Testing:**
- ✅ Real performance metrics
- ✅ Actual touch input behavior
- ✅ Real sensors (GPS, camera, etc.)
- ✅ Authentic network conditions
- ✅ True battery impact
- ✅ Real screen size/resolution

**When to Use Emulator (Optional):**
- No physical device available and testing is required
- Testing specific Android versions
- Automated CI/CD pipelines
- Testing different screen sizes/densities
- Note: Emulator is NOT required if using a real device

## Getting Started Now

1. Run environment validation
2. Check for connected devices: `adb devices`
3. Authorize device if needed
4. Read PRD.md
5. Create TODO.md with all tasks
6. Initialize PROGRESS.md and BUGS.md
7. Take first TODO item from top
8. Implement → Test on Device → Document → Commit → Push
9. Remove from TODO, add to PROGRESS
10. Take next TODO item
11. Repeat

**Let's build something great! 🚀**
