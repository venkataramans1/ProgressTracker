import SwiftUI

struct InsightsCoordinatorView: View {
    @ObservedObject var coordinator: InsightsCoordinator
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            InsightsView(
                viewModel: InsightsViewModel(
                    generateInsightsUseCase: container.generateInsightsUseCase
                )
            )
        }
    }
}
