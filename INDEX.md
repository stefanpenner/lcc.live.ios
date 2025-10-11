# 📚 Documentation Index

Quick links to all documentation.

## 🚀 Getting Started

1. **[QUICKSTART.md](QUICKSTART.md)** ⭐ **Start here!** (5 minutes to running)
2. **[README.md](README.md)** - Project overview & features
3. **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Where everything lives

## 🛠️ Development

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[.env.example](.env.example)** - Configuration options

## 🚢 Deployment

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - TestFlight & App Store guide
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

## 📁 Key Files

### Configuration
- `lcc/Config/Environment.swift` - All app settings
- `.env.local` - Your local overrides (create this)
- `.github/workflows/ios-testflight.yml` - CI/CD

### Core App
- `lcc/LCC.swift` - App entry point
- `lcc/MainView.swift` - Main UI
- `lcc/APIService.swift` - Backend API
- `lcc/ImagePreloader.swift` - Image caching

### Services
- `lcc/Services/MetricsService.swift` - Grafana metrics
- `lcc/Services/NetworkMonitor.swift` - Connection status
- `lcc/Utilities/Logger.swift` - Logging

### Automation
- `fastlane/Fastfile` - Deployment automation
- `scripts/setup_env.sh` - Dev environment setup

## 🎯 Common Tasks

| Task | See |
|------|-----|
| **Start developing** | [QUICKSTART.md](QUICKSTART.md) |
| **Deploy to TestFlight** | [DEPLOYMENT.md](DEPLOYMENT.md) section 5 |
| **Add a feature** | [CONTRIBUTING.md](CONTRIBUTING.md) section 3 |
| **Run tests** | `fastlane test` |
| **Find a file** | [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) |
| **Configure app** | Edit `.env.local` |
| **Understand architecture** | [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) section "How Components Connect" |

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| Build fails | See [QUICKSTART.md](QUICKSTART.md) "Troubleshooting" |
| Tests fail | See [CONTRIBUTING.md](CONTRIBUTING.md) "Testing" |
| Deployment fails | See [DEPLOYMENT.md](DEPLOYMENT.md) "Troubleshooting" |
| Images not loading | Check connection status in app |

## 📊 Architecture Overview

```
User Opens App
    ↓
LCC.swift (entry)
    ↓
MainView → APIService → lcc.live/api
         → ImagePreloader → Caches
         → MetricsService → Grafana
```

See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for detailed diagrams.

## 🔗 External Resources

- [Swift.org](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Fastlane Docs](https://docs.fastlane.tools/)
- [App Store Connect](https://appstoreconnect.apple.com/)

---

**Pro tip:** Bookmark this page! It's your map to the codebase.

