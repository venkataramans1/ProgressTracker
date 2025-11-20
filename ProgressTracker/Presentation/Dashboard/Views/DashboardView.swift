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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dateHeader
                statusFilterPicker
                contentSection
                addChallengeButton
                    .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
                onSave: { detail in
                    Task { await viewModel.update(detail: detail, for: item.id) }
                },
                onCancel: { editorItem = nil }
            )
        }
    }

    private var dateHeader: some View {
        Text(viewModel.dateHeaderText)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.secondary)
            .padding(.bottom, 4)
    }

    private var statusFilterPicker: some View {
        Picker("Status", selection: $viewModel.statusFilter) {
            ForEach(DashboardViewModel.ChallengeStatusFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var contentSection: some View {
        if viewModel.isLoading {
            LoadingStateView(text: "Loading challenges...")
                .frame(maxWidth: .infinity, alignment: .center)
        } else if viewModel.filteredChallenges.isEmpty {
            EmptyStateView(
                title: "No challenges",
                message: "Create a challenge to get started."
            )
        } else {
            challengeList
        }
    }

    private var challengeList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.filteredChallenges.enumerated()), id: \.element.id) { index, item in
                ChallengeRow(
                    item: item,
                    isExpanded: viewModel.expandedChallengeID == item.id,
                    onToggleExpansion: { viewModel.toggleExpansion(for: item.id) },
                    onToggleStatus: { Task { await viewModel.toggleCompletion(for: item.id) } },
                    onEditTapped: { editorItem = item },
                    onLogMinutes: { minutes in
                        Task { await viewModel.logMinutes(minutes, for: item.id) }
                    },
                    onSetLoggedMinutes: { total in
                        Task { await viewModel.setLoggedMinutes(total, for: item.id) }
                    }
                )
                .contextMenu {
                    Button("Open Details") { onChallengeSelected(item.challenge) }
                }
                if index < viewModel.filteredChallenges.count - 1 {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.leading, 56)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var addChallengeButton: some View {
        Button(action: onAddChallenge) {
            Text("+ Add Challenge")
                .fontWeight(.semibold)
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
