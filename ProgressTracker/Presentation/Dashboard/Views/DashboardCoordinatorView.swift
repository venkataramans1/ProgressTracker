import SwiftUI

struct DashboardCoordinatorView: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(
                viewModel: DashboardViewModel(
                    getActiveChallengesUseCase: container.getActiveChallengesUseCase,
                    calculateStreakUseCase: container.calculateStreakUseCase
                ),
                onChallengeSelected: { challenge in
                    coordinator.push(.challengeDetail(challenge))
                }
            )
            .navigationDestination(for: DashboardCoordinator.Destination.self) { destination in
                switch destination {
                case let .challengeDetail(challenge):
                    ChallengeDetailView(
                        viewModel: ChallengeDetailViewModel(
                            challenge: challenge,
                            saveChallengeUseCase: container.saveChallengeUseCase
                        )
                    )
                }
            }
        }
    }
}
