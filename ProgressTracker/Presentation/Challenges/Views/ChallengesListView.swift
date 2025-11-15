import SwiftUI

struct ChallengesListView: View {
    @StateObject private var viewModel: ChallengesListViewModel
    let onChallengeSelected: (Challenge) -> Void

    init(viewModel: ChallengesListViewModel, onChallengeSelected: @escaping (Challenge) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChallengeSelected = onChallengeSelected
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
                            ProgressView(value: challenge.progress)
                            Text(challenge.progress.formatted(.percent.precision(.fractionLength(0))))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Challenges")
        .task { await viewModel.load() }
    }
}
