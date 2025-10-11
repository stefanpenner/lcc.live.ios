# Quick Start - 5 Minutes to Running

## 1. Setup (One Command)

```bash
./scripts/setup_env.sh
```

This installs Fastlane, SwiftLint, and creates `.env.local` for you.

## 2. Open in Xcode

```bash
open lcc.xcodeproj
```

## 3. Run

Press `⌘ + R` or click the Play button.

That's it! The app runs on the simulator.

---

## Common Commands

```bash
# Run tests
fastlane test

# Build for device (requires signing setup)
fastlane build

# Deploy to TestFlight (requires Apple Developer account)
fastlane beta
```

---

## File Structure (Where Things Live)

```
lcc/
├── Config/Environment.swift      # All configuration (API URLs, timeouts)
├── Services/                      # Backend communication
│   ├── MetricsService.swift      # Grafana metrics
│   └── NetworkMonitor.swift      # Connection status
├── Utilities/Logger.swift         # Logging (replaces print)
├── APIService.swift               # Fetches camera feeds
├── ImagePreloader.swift           # Image caching
└── Views/                         # UI (SwiftUI)
    ├── MainView.swift            # Main screen
    ├── ConnectionStatusView.swift # Status indicator
    └── PhotoTabView.swift        # Image grid
```

---

## Configuration

Edit `.env.local` to customize:

```bash
# Use localhost backend
LCC_API_BASE_URL=http://localhost:3000

# Enable verbose logging  
DEBUG_LOGGING=true
```

Xcode will use these automatically.

---

## Testing

```bash
# Run all tests
fastlane test

# Or in Xcode
⌘ + U
```

---

## Next Steps

- **For deployment**: See `DEPLOYMENT.md`
- **For architecture**: See `PROJECT_STRUCTURE.md`
- **For changes**: See `CHANGELOG.md`

---

## Troubleshooting

**Build fails?**
```bash
# Clean everything
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData
```

**Images not loading?**
- Check lcc.live is accessible in browser
- Look at connection status indicator in app (top right)

**Tests failing?**
- Make sure you ran `./scripts/setup_env.sh` first

---

That's really all you need to know to get started! 🚀

