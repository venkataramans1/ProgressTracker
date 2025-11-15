import Foundation

/// Retrieves entries for insights and logs.
struct GetDailyEntriesUseCase {
    private let repository: DailyEntryRepository

    init(repository: DailyEntryRepository) {
        self.repository = repository
    }

    func execute(startingFrom startDate: Date, to endDate: Date) async throws -> [DailyEntry] {
        try await repository.fetchEntries(startingFrom: startDate, to: endDate)
    }
}
