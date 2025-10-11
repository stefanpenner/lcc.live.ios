# Project Structure

Quick visual guide to where everything lives.

## 📁 Directory Layout

```
lcc.live.ios/
│
├── 📱 lcc/                           # Main iOS app
│   ├── Config/
│   │   └── Environment.swift         # 🔧 All app configuration
│   │
│   ├── Services/                     # Backend services
│   │   ├── MetricsService.swift      # 📊 Grafana metrics collection
│   │   └── NetworkMonitor.swift      # 📡 Connection monitoring
│   │
│   ├── Utilities/
│   │   └── Logger.swift              # 📝 Structured logging (replaces NSLog)
│   │
│   ├── APIService.swift              # 🌐 Fetches camera feeds from lcc.live
│   ├── ImagePreloader.swift          # 💾 Image caching & memory management
│   ├── MediaItem.swift               # 📦 Data model (image or YouTube video)
│   │
│   ├── LCC.swift                     # 🚀 App entry point
│   ├── MainView.swift                # 🖼️ Main UI (tabs, grid, fullscreen)
│   ├── PhotoTabView.swift            # 📸 Image grid view
│   ├── ConnectionStatusView.swift    # 🟢 Status indicator (top right)
│   ├── FullScreenImageGalleryView.swift
│   ├── YouTubePlayerView.swift       # 🎥 YouTube embed support
│   │
│   ├── Assets.xcassets/              # App icons & colors
│   └── PrivacyInfo.xcprivacy         # 🔒 Required by Apple
│
├── 🧪 lccTests/
│   └── lccTests.swift                # Unit tests
│
├── 🤖 .github/workflows/
│   └── ios-testflight.yml            # CI/CD (auto-deploy on push)
│
├── ⚙️ fastlane/                      # Deployment automation
│   ├── Fastfile                      # Commands: test, build, beta, release
│   ├── Appfile                       # App ID & team settings
│   └── Matchfile                     # Code signing config
│
├── 🛠️ scripts/
│   ├── setup_env.sh                  # One-command dev setup
│   └── increment_build.sh            # Auto-bump build numbers
│
├── 📚 Documentation/
│   ├── README.md                     # Overview & features
│   ├── QUICKSTART.md                 # ⭐ Start here! (5 min to running)
│   ├── PROJECT_STRUCTURE.md          # This file
│   ├── DEPLOYMENT.md                 # TestFlight & App Store guide
│   └── CHANGELOG.md                  # Version history
│
├── ⚙️ Configuration Files
│   ├── .env.example                  # Environment variables template
│   ├── .gitignore                    # What not to commit
│   └── Gemfile                       # Ruby dependencies (Fastlane)
│
└── 🗂️ Build Outputs (gitignored)
    ├── build/                        # Xcode build artifacts
    ├── fastlane/report.xml           # Test results
    └── *.ipa                         # Built app packages
```

---

## 🎯 Key Files (Start Here)

If you're new to the codebase, read these files in order:

### 1. Configuration
- **`lcc/Config/Environment.swift`** - All settings in one place

### 2. App Entry
- **`lcc/LCC.swift`** - App starts here, sets up services

### 3. UI
- **`lcc/MainView.swift`** - Main screen, tab navigation
- **`lcc/PhotoTabView.swift`** - Image grid with refresh

### 4. Backend
- **`lcc/APIService.swift`** - Fetches camera feeds
- **`lcc/ImagePreloader.swift`** - Caches images

### 5. Utilities
- **`lcc/Utilities/Logger.swift`** - Use instead of `print()`
- **`lcc/Services/MetricsService.swift`** - Track app performance

---

## 🔄 Data Flow

```
User Opens App
    ↓
LCC.swift (entry point)
    ↓
MainView.swift
    ├── APIService.swift → Fetches from lcc.live/lcc.json
    │       ↓
    │   MediaItem[] (images & videos)
    │       ↓
    └── PhotoTabView.swift
            ├── ImagePreloader.swift → Caches images
            └── Grid UI → Shows cached images
```

---

## 🧩 How Components Connect

```
┌─────────────────────────────────────────────┐
│ LCC.swift (App Entry)                       │
│ • Initializes all services                  │
│ • Tracks app launch metrics                 │
└────────┬────────────────────────────────────┘
         │
         ├──> NetworkMonitor (watches connection)
         ├──> MetricsService (tracks performance)
         ├──> APIService (fetches camera feeds)
         └──> ImagePreloader (caches images)
                │
         ┌──────┴─────────────────────────────────┐
         │ MainView (Main UI)                     │
         │ • Tabs (LCC / BCC)                     │
         │ • Connection status indicator          │
         └───────┬────────────────────────────────┘
                 │
         ┌───────┴────────────────────────────────┐
         │ PhotoTabView (Image Grid)              │
         │ • Pull to refresh                      │
         │ • Grid modes (single/compact)          │
         │ • Fullscreen gallery                   │
         └────────────────────────────────────────┘
```

---

## 📊 Metrics Collection

Metrics automatically flow from app → your backend:

```
App Events (tap, load, error)
    ↓
MetricsService.swift (batches every 30s)
    ↓
POST https://lcc.live/api/metrics
    ↓
Grafana Dashboard
```

---

## 🔧 Configuration System

```
Environment Variables (.env.local)
    ↓
Environment.swift (loads & validates)
    ↓
Used by all services (API, Metrics, ImagePreloader)
```

**Example:**
```swift
// Instead of hardcoding:
let url = "https://lcc.live"

// Use:
let url = Environment.apiBaseURL  // Can be changed without rebuild
```

---

## 🧪 Testing Structure

```
lccTests/lccTests.swift
├── ImagePreloaderTests      # Caching & memory
├── APIServiceTests          # Network requests
├── MediaItemTests           # Data parsing
├── PhotoTabViewTests        # UI logic
├── EnvironmentTests         # Configuration
└── PresentedMediaTests      # Model tests
```

---

## 🚀 Deployment Flow

```
git push origin main
    ↓
GitHub Actions (.github/workflows/ios-testflight.yml)
    ↓
Run Tests (fastlane test)
    ↓
Build App (fastlane build)
    ↓
Upload to TestFlight (fastlane beta)
    ↓
Beta Testers Notified 🎉
```

---

## 💡 Where to Add Features

Want to add a feature? Start here:

| Feature | File to Edit |
|---------|--------------|
| New API endpoint | `lcc/APIService.swift` |
| New screen/view | Create in `lcc/` (e.g., `SettingsView.swift`) |
| App configuration | `lcc/Config/Environment.swift` |
| Custom logging | Use `Logger.swift` (already set up) |
| Track new metric | `lcc/Services/MetricsService.swift` |
| UI styling | SwiftUI views (e.g., `MainView.swift`) |
| Tests | `lccTests/lccTests.swift` |

---

## 🔍 Finding Things

**"Where is X?"**

- **API calls** → `APIService.swift`
- **Image caching** → `ImagePreloader.swift`
- **Logging** → `Utilities/Logger.swift`
- **Configuration** → `Config/Environment.swift`
- **Metrics** → `Services/MetricsService.swift`
- **Network status** → `Services/NetworkMonitor.swift`
- **Main UI** → `MainView.swift`
- **Image grid** → `PhotoTabView.swift`
- **Tests** → `lccTests/lccTests.swift`
- **Deployment** → `fastlane/Fastfile`
- **CI/CD** → `.github/workflows/ios-testflight.yml`

---

## 📖 Related Docs

- **Getting Started**: `QUICKSTART.md`
- **Full Deployment**: `DEPLOYMENT.md`
- **What's New**: `CHANGELOG.md`

