import SwiftUI

struct ChallengesCoordinatorView: View {
    @ObservedObject var coordinator: ChallengesCoordinator
    @EnvironmentObject private var container: DependencyContainer

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ChallengesListView(
                viewModel: ChallengesListViewModel(
                    getChallengesUseCase: container.getChallengesUseCase
                ),
                onChallengeSelected: { challenge in
                    coordinator.push(.challengeDetail(challenge))
                },
                onAddChallenge: {
                    coordinator.push(.newChallenge)
                }
            )
            .navigationDestination(for: ChallengesCoordinator.Destination.self) { destination in
                switch destination {
                case let .challengeDetail(challenge):
                    ChallengeDetailView(
                        viewModel: ChallengeDetailViewModel(
                            challenge: challenge,
                            saveChallengeUseCase: container.saveChallengeUseCase
                        )
                    )
                case .newChallenge:
                    NewChallengeFlowView(
                        viewModel: NewChallengeViewModel(
                            saveChallengeUseCase: container.saveChallengeUseCase
                        ),
                        onCancel: { coordinator.pop() },
                        onSaved: { _ in coordinator.pop() }
                    )
                }
            }
        }
    }
}
