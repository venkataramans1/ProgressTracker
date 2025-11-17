# ProgressTracker Phase Summary

## Phase 1 – Data & Persistence (Complete)
- Versioned Core Data model (`ProgressTrackerModel 1` → `ProgressTrackerModel 2`) adding `ChallengeDetail`, mood timestamps, challenge metadata, and relationships.
- Updated domain entities and built new entity mappers plus `DailyEntry+Legacy` helpers for backward compatibility.
- Enhanced repositories with graph hydration/persistence, status-filtered queries, `PhotoStorageHelper`, and a manual `CoreDataMigrator` for safe v1→v2 migrations.
- `SampleDataService` now seeds the richer schema on first launch.

## Phase 2 – UI/UX Refactor (Complete)
- Replaced 4-tab layout with 3-tab TabView (`Dashboard`, `Insights`, `Settings`) via the new `MainView`.
- Implemented merged dashboard experience (`DashboardTab`, `DashboardView`) featuring date picker, mood selector, status filter, expandable `ChallengeRow`s, and checkbox-based status toggles.
- Added `ChallengeDetailEditor` sheet for notes/photo management powered by `PhotoStorageHelper`.
- Updated coordinators to drive the new dashboard flow; added `ChallengeRow`, `ChallengeDetailEditor`, `DashboardTab`, `MainView`, `SettingsView` to the target.
- `DailyEntry+Legacy` adjusted for the refactored data model.

## Troubleshooting In Progress
- Simulator still logs `CoreData: Failed to load model named ProgressTrackerModel`, causing dashboard/insights to show "Loading challenges…".
- Actions taken:
  - `.xccurrentversion` now points to `ProgressTrackerModel 2.xcdatamodel` and the Xcode project has been updated so the bundle’s `XCVersionGroup` includes both `ProgressTrackerModel.xcdatamodel` and `ProgressTrackerModel 2.xcdatamodel` (so the model now expands properly in Xcode).
  - Verified the model bundle is included in Copy Bundle Resources and the built product contains `ProgressTrackerModel.momd`.
  - Cleared DerivedData and reinstalled the app on the simulator.
- Next steps:
  1. Clean build folder and rebuild so the updated `.xccurrentversion` and version-group metadata propagate.
  2. Inspect the simulator app bundle to confirm `ProgressTrackerModel.momd` exists (`~/Library/Developer/CoreSimulator/.../ProgressTracker.app`).
  3. Add logging/breakpoint inside `CoreDataStack` to verify which model URL `NSPersistentContainer` loads and ensure it resolves to the `.momd` inside the app.
  4. If the bundle looks correct yet Core Data still fails, investigate simulator caches (e.g., `xcrun simctl erase <Device>`).

Once Core Data loads the v2 model, the dashboard and insights tabs should populate with sample data instead of spinning.
