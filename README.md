# LensTracker

A native iOS app for tracking contact lens replacement schedules. Stay on top of when to change your lenses with timers, reminders, and compliance stats.

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![SwiftData](https://img.shields.io/badge/Data-SwiftData-green)

## Features

### Timer
- Circular progress indicator showing days remaining until lens replacement
- Color-coded status: blue (normal), orange (≤3 days), red (overdue)
- Quick actions to change or reset lenses
- Shortcut buttons for switching lens types (Daily, Bi-Weekly, Monthly)

### Prescription Management
- Store contact lens prescriptions with full optometry fields per eye (OD/OS)
- Sphere, Cylinder, Axis, Base Curve, Diameter, Add power
- Doctor/clinic info and expiration tracking
- Formatted display matching standard optometry notation

### History
- Chronological log of all lens pairs worn
- Duration tracking with compliance color coding
- Active lens indicator

### Statistics
- Total pairs used
- Average wear duration
- On-time replacement rate
- Best consecutive compliance streak

### Notifications
- Day-before reminder
- Due-date alert
- Overdue warning

### Home & Lock Screen Widgets
- Small widget with circular timer dial
- Medium widget with timer, type, and date info
- Lock screen widgets (circular, rectangular, and inline)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Data | SwiftData |
| Architecture | MVVM with `@Observable` |
| Notifications | UserNotifications |
| Widgets | WidgetKit |
| Widget Sync | App Groups + UserDefaults |

No third-party dependencies — built entirely with Apple frameworks.

## Project Structure

```
LensTracker/
├── LensTrackerApp.swift          # App entry point
├── ContentView.swift             # Main TabView
├── Models/
│   ├── LensRecord.swift          # Lens wear data model
│   └── Prescription.swift        # Prescription data model
├── ViewModels/
│   └── LensViewModel.swift       # Core state management
├── Views/
│   ├── TimerView.swift           # Active lens timer
│   ├── PrescriptionView.swift    # Prescription list & add
│   ├── PrescriptionDetailView.swift
│   ├── HistoryView.swift         # Past lens pairs
│   └── StatsView.swift           # Usage statistics
├── Services/
│   ├── NotificationManager.swift # Push notifications
│   └── SharedDataManager.swift   # Widget data sync
LensTrackerWidget/
├── LensTrackerWidget.swift       # Widget definitions
└── LensTrackerWidgetBundle.swift  # Widget bundle entry
```

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

1. Clone the repository
2. Open `LensTracker.xcodeproj` in Xcode
3. Build and run on a simulator or device

## License

This project is for personal use.
