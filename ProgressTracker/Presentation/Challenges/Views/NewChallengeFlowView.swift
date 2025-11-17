import SwiftUI

struct NewChallengeFlowView: View {
    @StateObject private var viewModel: NewChallengeViewModel
    let onCancel: () -> Void
    let onSaved: (Challenge) -> Void

    init(
        viewModel: NewChallengeViewModel,
        onCancel: @escaping () -> Void,
        onSaved: @escaping (Challenge) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onCancel = onCancel
        self.onSaved = onSaved
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader
            stepContent
        }
        .padding()
        .navigationTitle("New Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { onCancel() }
            }
        }
        .safeAreaInset(edge: .bottom) { actionBar }
        .alert(
            "Unable to Save",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving challenge...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .onChange(of: viewModel.savedChallenge) { challenge in
            guard let challenge = challenge else { return }
            onSaved(challenge)
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(viewModel.stepIndex + 1) of \(viewModel.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(viewModel.currentStep.title)
                .font(.title2.bold())
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            ProgressView(value: viewModel.progress)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch viewModel.currentStep {
                case .overview:
                    overviewSection
                case .objectives:
                    objectivesSection
                case .review:
                    reviewSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 140)
        }
    }

    private var overviewSection: some View {
        VStack(spacing: 16) {
            GroupBox("Challenge Basics") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                    TextField("Description", text: $viewModel.detail, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                }
            }

            GroupBox("Schedule") {
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    Toggle("Set an end date", isOn: $viewModel.includeEndDate.animation())
                    if viewModel.includeEndDate {
                        DatePicker(
                            "End Date",
                            selection: $viewModel.endDate,
                            in: viewModel.startDate...,
                            displayedComponents: .date
                        )
                    }
                }
            }

            GroupBox("Identity") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Emoji or short label", text: $viewModel.emoji)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    private var objectivesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(viewModel.objectives.indices), id: \.self) { index in
                let objectiveID = viewModel.objectives[index].id
                ObjectiveEditorCard(
                    objective: $viewModel.objectives[index],
                    onRemove: { viewModel.removeObjective(id: objectiveID) },
                    onAddMilestone: { viewModel.addMilestone(to: objectiveID) },
                    onRemoveMilestone: { milestoneID in
                        viewModel.removeMilestone(milestoneID, from: objectiveID)
                    },
                    canRemove: viewModel.objectives.count > 1
                )
            }

            Button {
                viewModel.addObjective()
            } label: {
                Label("Add Objective", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Summary") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.displayTitle)
                        .font(.headline)
                    if let detail = viewModel.detailSummary {
                        Text(detail)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        Text(viewModel.startDate, style: .date)
                        if viewModel.includeEndDate {
                            Image(systemName: "arrow.right")
                            Text(viewModel.endDate, style: .date)
                        }
                    }
                    .font(.subheadline)
                    if let emojiValue = viewModel.displayEmoji {
                        Text("Emoji: \(emojiValue)")
                            .font(.subheadline)
                    }
                }
            }

            GroupBox("Objectives") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(viewModel.objectives.enumerated()), id: \.element.id) { index, objective in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                objective.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? "Untitled Objective"
                                    : objective.title.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                                .font(.headline)
                            Text("Target: \(objective.targetValue.formatted()) \(objective.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !objective.milestones.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Milestones")
                                        .font(.subheadline.bold())
                                    ForEach(objective.milestones) { milestone in
                                        HStack {
                                            Image(systemName: "checkmark.seal")
                                                .foregroundColor(.accentColor)
                                            VStack(alignment: .leading) {
                                                Text(milestone.title)
                                                Text(milestone.targetDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        if index < viewModel.objectives.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        HStack {
            if viewModel.currentStep != .overview {
                Button("Back") { viewModel.goBack() }
            }
            Spacer()
            Button(viewModel.primaryButtonTitle) {
                if viewModel.currentStep == .review {
                    Task { await viewModel.save() }
                } else {
                    viewModel.advance()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canAdvanceFromCurrentStep)
        }
        .padding()
        .background(.ultraThinMaterial)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -1)
    }
}

private struct ObjectiveEditorCard: View {
    @Binding var objective: NewChallengeViewModel.ObjectiveDraft
    let onRemove: () -> Void
    let onAddMilestone: () -> Void
    let onRemoveMilestone: (NewChallengeViewModel.MilestoneDraft.ID) -> Void
    let canRemove: Bool

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TextField("Objective title", text: $objective.title)
                        .textFieldStyle(.roundedBorder)
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                    }
                    .disabled(!canRemove)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Remove objective")
                }
                HStack(spacing: 12) {
                    TextField("Target value", value: $objective.targetValue, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Unit", text: $objective.unit)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Milestones")
                            .font(.subheadline.bold())
                        Spacer()
                        Button(action: onAddMilestone) {
                            Label("Add Milestone", systemImage: "plus.circle")
                        }
                    }
                    if objective.milestones.isEmpty {
                        Text("No milestones yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach($objective.milestones) { $milestone in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    TextField("Title", text: $milestone.title)
                                        .textFieldStyle(.roundedBorder)
                                    Button(role: .destructive) {
                                        onRemoveMilestone(milestone.id)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                    }
                                    .accessibilityLabel("Remove milestone")
                                }
                                DatePicker(
                                    "Target date",
                                    selection: $milestone.targetDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}
