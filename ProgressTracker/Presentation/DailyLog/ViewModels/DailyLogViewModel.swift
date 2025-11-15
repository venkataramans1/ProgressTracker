import Foundation

/// Handles form state for creating daily log entries.
@MainActor
final class DailyLogViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var notes: String = ""
    @Published var mood: Mood = .good
    @Published var focusHours: Double = 1
    @Published var exerciseMinutes: Double = 15
    @Published private(set) var recentEntries: [DailyEntry] = []
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var saveSuccess: Bool = false

    private let saveDailyEntryUseCase: SaveDailyEntryUseCase
    private let getDailyEntriesUseCase: GetDailyEntriesUseCase
    private let calendar: Calendar

    init(
        saveDailyEntryUseCase: SaveDailyEntryUseCase,
        getDailyEntriesUseCase: GetDailyEntriesUseCase,
        calendar: Calendar = .current
    ) {
        self.saveDailyEntryUseCase = saveDailyEntryUseCase
        self.getDailyEntriesUseCase = getDailyEntriesUseCase
        self.calendar = calendar
        Task { await loadRecentEntries() }
    }

    /// Persists the current form state to the repository.
    func save() async {
        isSaving = true
        errorMessage = nil
        saveSuccess = false
        let metrics = [
            "Focus (hrs)": focusHours,
            "Exercise (mins)": exerciseMinutes
        ]
        let entry = DailyEntry(
            date: selectedDate,
            notes: notes,
            mood: mood,
            metrics: metrics,
            isCompleted: true
        )
        do {
            try await saveDailyEntryUseCase.execute(entry)
            saveSuccess = true
            await loadRecentEntries()
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    /// Loads the latest entries for quick review.
    func loadRecentEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            let end = Date()
            let start = calendar.date(byAdding: .day, value: -14, to: end) ?? end
            recentEntries = try await getDailyEntriesUseCase.execute(startingFrom: start, to: end)
                .sorted { $0.date > $1.date }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func resetForm() {
        selectedDate = Date()
        notes = ""
        mood = .good
        focusHours = 1
        exerciseMinutes = 15
    }
}
