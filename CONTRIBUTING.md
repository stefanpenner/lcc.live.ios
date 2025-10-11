# Contributing to LCC.live iOS

Thanks for contributing! Here's how to get started.

## Quick Setup

```bash
# 1. Fork & clone
git clone https://github.com/your-username/lcc.live.ios.git
cd lcc.live.ios

# 2. Setup environment
./scripts/setup_env.sh

# 3. Create branch
git checkout -b feature/my-feature

# 4. Make changes & test
fastlane test

# 5. Submit PR
git push origin feature/my-feature
```

## Development Workflow

### 1. Local Development

```bash
# Open in Xcode
open lcc.xcodeproj

# Run on simulator
⌘ + R

# Run tests
⌘ + U
# or
fastlane test
```

### 2. Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint (auto-runs in CI)
- Use `Logger` instead of `print()`
- Add tests for new features
- Document public APIs

**Example:**
```swift
// ✅ Good
Logger.networking.info("API call succeeded")

// ❌ Bad
print("API succeeded")
```

### 3. Making Changes

| Change | Files to Edit |
|--------|--------------|
| Add API endpoint | `lcc/APIService.swift` |
| New UI screen | Create `lcc/YourView.swift` |
| Add configuration | `lcc/Config/Environment.swift` |
| Add metric | `lcc/Services/MetricsService.swift` |
| Fix bug | Relevant file + add test |

### 4. Testing

```bash
# Run all tests
fastlane test

# Test specific suite
xcodebuild test -scheme lcc -only-testing:lccTests/YourTestSuite
```

**Write tests for:**
- New features
- Bug fixes
- Public APIs

### 5. Documentation

Update docs when you change:
- Public APIs → Add doc comments
- Configuration → Update `PROJECT_STRUCTURE.md`
- New features → Update `README.md`
- Breaking changes → Update `CHANGELOG.md`

### 6. Submitting PR

**Before submitting:**

```bash
# Run tests
fastlane test

# Check lint
swiftlint

# Test on device (if possible)
fastlane build
```

**PR Title Format:**
- `feat: Add dark mode support`
- `fix: Crash when loading images`
- `docs: Update deployment guide`
- `refactor: Simplify APIService`

**PR Description:**
```markdown
## What
Brief description of change

## Why
Why this change is needed

## Testing
How you tested it

## Screenshots
(if UI change)
```

## Project Structure

```
lcc/
├── Config/          # Configuration
├── Services/        # Backend services
├── Utilities/       # Helpers (Logger, etc.)
├── Views/           # SwiftUI views
└── *.swift          # Main app files
```

See [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) for complete layout.

## Common Tasks

### Add a New Metric

```swift
// 1. Add event to MetricsService.swift
enum Event: String {
    case myNewEvent = "my_new_event"
}

// 2. Track it
MetricsService.shared.track(event: .myNewEvent, tags: ["key": "value"])
```

### Add Configuration Option

```swift
// 1. Add to Environment.swift
static var myOption: String {
    ProcessInfo.processInfo.environment["MY_OPTION"] ?? "default"
}

// 2. Document in .env.example
// MY_OPTION=value

// 3. Use it
let value = Environment.myOption
```

### Add a New Screen

```swift
// 1. Create lcc/MyNewView.swift
import SwiftUI

struct MyNewView: View {
    var body: some View {
        Text("Hello!")
    }
}

// 2. Add to navigation
// In MainView.swift or wherever
MyNewView()
```

## Code Review Process

1. **Automated checks** run on PR (tests, lint)
2. **Manual review** by maintainer
3. **Address feedback** if any
4. **Merge** when approved

## Release Process

1. Update version: `fastlane bump_version type:minor`
2. Update `CHANGELOG.md`
3. Push to `main`
4. GitHub Actions auto-deploys to TestFlight
5. Test on TestFlight
6. Promote to production when ready

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/your-username/lcc.live.ios/issues)
- **Docs**: See `README.md` and `PROJECT_STRUCTURE.md`
- **Questions**: Open a discussion or issue

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn

Thanks for contributing! 🙏

