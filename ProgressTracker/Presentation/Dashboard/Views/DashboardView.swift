import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    let onChallengeSelected: (Challenge) -> Void

    init(viewModel: DashboardViewModel, onChallengeSelected: @escaping (Challenge) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChallengeSelected = onChallengeSelected
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView(text: "Loading dashboard...")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error, retryAction: { Task { await viewModel.load() } })
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        streakSection
                        activeChallengesSection
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Dashboard")
            }
        }
        .task { await viewModel.load() }
    }

    private var headerSection: some View {
        ProgressSummaryCard(
            title: "Overall Progress",
            value: viewModel.overallProgress.formatted(.percent.precision(.fractionLength(0))),
            subtitle: "Average completion across all active challenges",
            progress: viewModel.overallProgress
        )
    }

    private var streakSection: some View {
        ProgressSummaryCard(
            title: "Current Streak",
            value: "\(viewModel.streakCount) days",
            subtitle: "Consecutive days logged",
            progress: min(Double(viewModel.streakCount) / 30, 1)
        )
    }

    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Challenges")
                .font(.title2.bold())
            if viewModel.activeChallenges.isEmpty {
                EmptyStateView(title: "No active challenges", message: "Create a new challenge to get started.")
            } else {
                ForEach(viewModel.activeChallenges) { challenge in
                    Button {
                        onChallengeSelected(challenge)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(challenge.title)
                                    .font(.headline)
                                Spacer()
                                Text(challenge.progress.formatted(.percent.precision(.fractionLength(0))))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: challenge.progress)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
