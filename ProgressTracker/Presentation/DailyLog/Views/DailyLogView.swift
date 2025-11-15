import SwiftUI

struct DailyLogView: View {
    @StateObject private var viewModel: DailyLogViewModel
    let onEntrySelected: (DailyEntry) -> Void

    init(viewModel: DailyLogViewModel, onEntrySelected: @escaping (DailyEntry) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onEntrySelected = onEntrySelected
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                formSection
                historySection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Daily Log")
        .alert("Saved", isPresented: $viewModel.saveSuccess, actions: {
            Button("OK", role: .cancel) {}
        })
        .overlay(alignment: .bottom) {
            if viewModel.isSaving {
                ProgressView("Saving entry...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding()
            }
        }
        .task { await viewModel.loadRecentEntries() }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Entry")
                .font(.title2.bold())
            DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
            VStack(alignment: .leading) {
                Text("Focus Hours: \(viewModel.focusHours, format: .number.precision(.fractionLength(1)))")
                Slider(value: $viewModel.focusHours, in: 0...10, step: 0.5)
            }
            VStack(alignment: .leading) {
                Text("Exercise Minutes: \(Int(viewModel.exerciseMinutes))")
                Slider(value: $viewModel.exerciseMinutes, in: 0...120, step: 5)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood")
                MoodSelectorView(selectedMood: $viewModel.mood)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                TextEditor(text: $viewModel.notes)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.gray.opacity(0.3))
                    )
            }
            Button {
                Task { await viewModel.save() }
            } label: {
                Label("Save Entry", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.title2.bold())
            if viewModel.isLoading {
                LoadingStateView(text: "Loading entries...")
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error, retryAction: { Task { await viewModel.loadRecentEntries() } })
            } else if viewModel.recentEntries.isEmpty {
                EmptyStateView(title: "No entries yet", message: "Log your progress to see history here.")
            } else {
                ForEach(viewModel.recentEntries) { entry in
                    Button {
                        onEntrySelected(entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date, style: .date)
                                    .font(.headline)
                                Text(entry.notes)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: entry.mood.systemImageName)
                                .foregroundColor(.accentColor)
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
