# ProgressTracker

iOS progress tracker app inspired by Bill Ackman's approach to overcoming tough situations. Track goals, log progress, and visualize achievements.

## Project Structure

The project follows a Clean Architecture + MVVM composition:

- `Presentation/`: SwiftUI views, view models, coordinators, and reusable components.
- `Domain/`: Business entities, repository contracts, and use case definitions.
- `Data/`: Core Data repositories, mappers, and persistence services.
- `Resources/`: Shared resources including the Core Data model.

Additional documentation lives in `docs/iphone_progress_tracker_architecture.md`.

## Getting Started

1. Open `ProgressTracker.xcodeproj` in Xcode 15 or later.
2. Select the **ProgressTracker** target and choose an iOS 16+ simulator or device.
3. Build and run. Sample data is populated on first launch for immediate exploration.

### Branch to check out

The Phase 2 UI/UX refactor now lives on the `develop` branch. To grab it locally from the
remote, create/update a local `develop` branch that tracks `origin/develop`:

```bash
git fetch origin develop:develop
git checkout develop
```

If your clone predates the publication of `origin/develop`, ask the maintainer to push the
branch (or rebase it onto `feature/ui-ux-refactor`) before opening the project in Xcode.
That keeps you from chasing commit hashes that only existed on an unshared branch and
prevents `fatal: reference is not a tree` errors.

## Features

- Dashboard with aggregated progress and streak tracking
- Quick daily logging with mood selector and metric sliders
- Challenge explorer with a single-screen creator, emoji suggestions, and flexible tracking styles
- Insights tab powered by Swift Charts
- Local notifications reminding you to log progress daily

## Requirements

- Xcode 15+
- iOS 16+ deployment target
- Swift 5.9+
