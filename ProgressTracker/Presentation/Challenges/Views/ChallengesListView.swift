import SwiftUI

struct ChallengesListView: View {
    @StateObject private var viewModel: ChallengesListViewModel
    let onChallengeSelected: (Challenge) -> Void
    let onAddChallenge: () -> Void

    init(
        viewModel: ChallengesListViewModel,
        onChallengeSelected: @escaping (Challenge) -> Void,
        onAddChallenge: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChallengeSelected = onChallengeSelected
        self.onAddChallenge = onAddChallenge
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView(text: "Loading challenges...")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error, retryAction: { Task { await viewModel.load() } })
            } else if viewModel.challenges.isEmpty {
                EmptyStateView(title: "No challenges", message: "Create your first challenge to track progress.")
            } else {
                List(viewModel.challenges) { challenge in
                    Button {
                        onChallengeSelected(challenge)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(challenge.title)
                                .font(.headline)
                            Text(challenge.detail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            Text(challenge.trackingStyle.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let target = challenge.dailyTargetMinutes, challenge.trackingStyle == .trackTime {
                                Text("Daily focus target: \(target) min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Challenges")
        .task { await viewModel.load() }
        .onAppear { Task { await viewModel.load() } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onAddChallenge) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Challenge")
            }
        }
    }
}
