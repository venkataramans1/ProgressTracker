import SwiftUI

/// Dashboard view used by the legacy coordinator flow.
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    let onChallengeSelected: (Challenge) -> Void
    let onAddChallenge: () -> Void

    @State private var editorItem: DashboardViewModel.ChallengeItem?

    init(
        viewModel: DashboardViewModel,
        onChallengeSelected: @escaping (Challenge) -> Void,
        onAddChallenge: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onChallengeSelected = onChallengeSelected
        self.onAddChallenge = onAddChallenge
    }

    var body: some View {
        VStack(spacing: 16) {
            dateSelector
            moodSelector
            statusFilterPicker
            contentSection
            addChallengeButton
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Dashboard")
        .toolbar { toolbarContent }
        .task { await viewModel.refresh() }
        .refreshable { await viewModel.refresh() }
        .onAppear { Task { await viewModel.refresh() } }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $editorItem) { item in
            ChallengeDetailEditor(
                challenge: item.challenge,
                detail: item.detail,
                mood: viewModel.mood,
                onSave: { detail, mood in
                    Task { await viewModel.update(detail: detail, for: item.id, mood: mood) }
                },
                onCancel: { editorItem = nil }
            )
        }
    }

    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Entry Date")
                .font(.headline)
            DatePicker(
                "Entry Date",
                selection: Binding(
                    get: { viewModel.selectedDate },
                    set: { viewModel.setSelectedDate($0) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood")
                .font(.headline)
            MoodSelectorView(
                selectedMood: Binding(
                    get: { viewModel.mood },
                    set: { viewModel.updateMood($0) }
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusFilterPicker: some View {
        Picker("Status", selection: $viewModel.statusFilter) {
            ForEach(DashboardViewModel.ChallengeStatusFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                LoadingStateView(text: "Loading challenges...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.filteredChallenges.isEmpty {
                EmptyStateView(
                    title: "No challenges",
                    message: "Create a challenge to get started."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredChallenges) { item in
                            ChallengeRow(
                                item: item,
                                isExpanded: viewModel.expandedChallengeID == item.id,
                                onToggleExpansion: { viewModel.toggleExpansion(for: item.id) },
                                onToggleStatus: { Task { await viewModel.toggleCompletion(for: item.id) } },
                                onEditTapped: { editorItem = item }
                            )
                            .contextMenu {
                                Button("Open Details") { onChallengeSelected(item.challenge) }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var addChallengeButton: some View {
        Button(action: onAddChallenge) {
            Label("Add Challenge", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("addChallengeButton")
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isSaving {
                ProgressView()
            }
        }
    }
}
