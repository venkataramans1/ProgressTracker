# Progress Tracker iPhone Architecture

This document summarises the architectural approach used for the Progress Tracker iOS application. The codebase follows a modularised MVVM + Clean Architecture layout with distinct responsibilities for the Presentation, Domain and Data layers. A lightweight coordinator pattern orchestrates navigation between the primary feature areas.

## Layers

### Presentation
* SwiftUI views organised by feature (Dashboard, Daily Log, Challenges, Insights).
* Feature views are paired with view models located under `Presentation/<Feature>/ViewModels`.
* Common UI components (loading, error, empty states, selectors) reside in `Presentation/Components`.
* Coordinators own navigation stacks per tab and are exposed via `Presentation/Coordinators`.

### Domain
* Pure Swift value types that model the business entities (`Challenge`, `Objective`, `Milestone`, `DailyEntry`, `Mood`).
* Repository protocols define contracts for data access.
* Use cases orchestrate a single piece of domain logic and are injected into view models.

### Data
* Core Data implementations of repositories live in `Data/CoreData/Repositories`.
* Entity mappers convert between managed objects and domain models to maintain isolation.
* `CoreDataStack` manages the persistent store configuration.
* Support services (`LocalNotificationService`, `SampleDataService`) provide integration with the system.

## Navigation
* `AppCoordinator` owns the dependency container and exposes a tab-based navigation hierarchy.
* Feature-specific coordinators wrap each tab in a `NavigationStack` allowing push navigation to detail screens.

## Dependency Injection
* `DependencyContainer` wires repositories, use cases and sample data seeding. The container is injected into the SwiftUI environment for easy access.

## Testing Data
* `SampleDataService` seeds Core Data with sample challenges and daily entries for immediate evaluation of the UI without manual setup.

