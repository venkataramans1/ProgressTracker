import Foundation

/// Produces aggregated analytics for the insights dashboard.
struct GenerateInsightsUseCase {
    private let repository: DailyEntryRepository
    private let calendar: Calendar

    init(repository: DailyEntryRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    func execute(forDays days: Int) async throws -> [DailyEntry] {
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        return try await repository.fetchEntries(startingFrom: startDate, to: endDate)
    }
}
