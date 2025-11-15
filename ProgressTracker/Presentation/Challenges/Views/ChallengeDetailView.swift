import SwiftUI

struct ChallengeDetailView: View {
    @StateObject private var viewModel: ChallengeDetailViewModel

    init(viewModel: ChallengeDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Overview") {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text(viewModel.challenge.progress.formatted(.percent.precision(.fractionLength(0))))
                }
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
                if !viewModel.challenge.detail.isEmpty {
                    Text(viewModel.challenge.detail)
                        .font(.body)
                }
            }

            Section("Objectives") {
                ForEach(viewModel.challenge.objectives) { objective in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(objective.title)
                                .font(.headline)
                            Spacer()
                            Text(objective.progress.formatted(.percent.precision(.fractionLength(0))))
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: objective.progress)
                        Text("\(Int(objective.currentValue)) / \(Int(objective.targetValue)) \(objective.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !objective.milestones.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Milestones")
                                    .font(.subheadline.bold())
                                ForEach(objective.milestones) { milestone in
                                    Button {
                                        viewModel.toggleMilestone(milestone, in: objective)
                                    } label: {
                                        HStack {
                                            Image(systemName: milestone.isCompleted ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(milestone.isCompleted ? .green : .gray)
                                            VStack(alignment: .leading) {
                                                Text(milestone.title)
                                                Text(milestone.targetDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(viewModel.challenge.title)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { saveButton } }
        .alert("Saved", isPresented: $viewModel.saveSucceeded) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your updates have been saved.")
        }
        .overlay(alignment: .bottom) {
            if viewModel.isSaving {
                ProgressView("Saving challenge...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding()
            }
        }
    }

    private var saveButton: some View {
        Button("Save") {
            Task { await viewModel.save() }
        }
    }
}
