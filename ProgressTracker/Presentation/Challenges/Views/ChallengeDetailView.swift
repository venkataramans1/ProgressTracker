import SwiftUI

struct ChallengeDetailView: View {
    @StateObject private var viewModel: ChallengeDetailViewModel

    init(viewModel: ChallengeDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Overview") {
                if let emoji = viewModel.challenge.emoji {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Text(emoji)
                    }
                }
                if !viewModel.challenge.detail.isEmpty {
                    Text(viewModel.challenge.detail)
                        .font(.body)
                } else {
                    Text("No description provided.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Section("Tracking style") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.challenge.trackingStyle.title)
                        .font(.headline)
                    Text(viewModel.challenge.trackingStyle.helperText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if viewModel.challenge.trackingStyle == .trackTime {
                        if let target = viewModel.challenge.dailyTargetMinutes {
                            Text("Daily focus target: \(target) minutes")
                                .font(.subheadline)
                        } else {
                            Text("No daily target set. Completion is manual.")
                                .font(.subheadline)
                        }
                    }
                }
            }

            Section("Schedule") {
                HStack {
                    Text("Start Date")
                    Spacer()
                    Text(viewModel.challenge.startDate, style: .date)
                }
                if let endDate = viewModel.challenge.endDate {
                    HStack {
                        Text("End Date")
                        Spacer()
                        Text(endDate, style: .date)
                    }
                }
            }
        }
        .navigationTitle(viewModel.challenge.title)
    }
}
