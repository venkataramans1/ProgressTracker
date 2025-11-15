import SwiftUI

struct DailyLogCoordinatorView: View {
    @ObservedObject var coordinator: DailyLogCoordinator
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DailyLogView(
                viewModel: DailyLogViewModel(
                    saveDailyEntryUseCase: container.saveDailyEntryUseCase,
                    getDailyEntriesUseCase: container.getDailyEntriesUseCase
                ),
                onEntrySelected: { entry in
                    coordinator.push(.entryDetail(entry))
                }
            )
            .navigationDestination(for: DailyLogCoordinator.Destination.self) { destination in
                switch destination {
                case let .entryDetail(entry):
                    DailyEntryDetailView(entry: entry)
                }
            }
        }
    }
}
