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
        ScrollView {
            VStack(spacing: 16) {
                overviewSection
                summarySection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 120)
            .padding()
        }
        .navigationTitle("New Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { onCancel() }
            }
        }
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
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Create Challenge") {
                    Task { await viewModel.save() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -1)
        }
        .onChange(of: viewModel.savedChallenge) { challenge in
            guard let challenge = challenge else { return }
            onSaved(challenge)
        }
        .onAppear {
            viewModel.generateEmojiSuggestions()
        }
    }

    private var overviewSection: some View {
        VStack(spacing: 16) {
            GroupBox("Challenge Basics") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Title", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: viewModel.title) { _ in
                            viewModel.generateEmojiSuggestions()
                        }
                    if !viewModel.isTitleValid {
                        Text("Title is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
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
                    if !viewModel.suggestedEmojis.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Suggestions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.suggestedEmojis, id: \.self) { emoji in
                                        Button(emoji) {
                                            viewModel.selectEmojiSuggestion(emoji)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            GroupBox("Tracking Style") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Tracking Style", selection: $viewModel.trackingStyle) {
                        ForEach(Challenge.TrackingStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.trackingStyle == .trackTime {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Daily target minutes (optional)", text: $viewModel.dailyTargetMinutesString)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            if let error = viewModel.dailyTargetValidationMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text("Leave blank if you don't have a target.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.trackingStyle) { style in
                    if style == .simpleCheck {
                        viewModel.dailyTargetMinutesString = ""
                    }
                }
            }
        }
    }

    private var summarySection: some View {
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
                Text("Tracking: \(viewModel.trackingStyle == .trackTime ? "Track time" : "Simple check")")
                    .font(.subheadline)
                if viewModel.trackingStyle == .trackTime, let target = viewModel.dailyTargetMinutes {
                    Text("Target: \(target) min/day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
