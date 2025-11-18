import SwiftUI

struct DashboardCoordinatorView: View {
    @ObservedObject var coordinator: DashboardCoordinator
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            DashboardView(
                viewModel: DashboardViewModel(
                    getActiveChallengesUseCase: container.getActiveChallengesUseCase,
                    dailyEntryRepository: container.dailyEntryRepository,
                    saveDailyEntryUseCase: container.saveDailyEntryUseCase
                ),
                onChallengeSelected: { challenge in
                    coordinator.push(.challengeDetail(challenge))
                },
                onAddChallenge: {
                    coordinator.push(.newChallenge)
                }
            )
            .navigationDestination(for: DashboardCoordinator.Destination.self) { destination in
                switch destination {
                case let .challengeDetail(challenge):
                    ChallengeDetailView(
                        viewModel: ChallengeDetailViewModel(challenge: challenge)
                    )
                case .newChallenge:
                    NewChallengeFlowView(
                        viewModel: NewChallengeViewModel(
                            saveChallengeUseCase: container.saveChallengeUseCase
                        ),
                        onCancel: {
                            coordinator.pop()
                        },
                        onSaved: { _ in
                            coordinator.pop()
                        }
                    )
                }
            }
        }
    }
}
