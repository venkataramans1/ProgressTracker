import Foundation

/// Calculates the current streak length based on saved daily entries.
struct CalculateStreakUseCase {
    private let repository: DailyEntryRepository

    init(repository: DailyEntryRepository) {
        self.repository = repository
    }

    func execute() async throws -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            return 0
        }
        let entries = try await repository.fetchEntries(startingFrom: startDate, to: endDate)
            .sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = endDate

        for entry in entries {
            if entry.isCompleted && calendar.isDate(entry.date, inSameDayAs: currentDate) {
                streak += 1
                guard let nextDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = nextDate
            } else if entry.date < currentDate {
                break
            }
        }
        return streak
    }
}
