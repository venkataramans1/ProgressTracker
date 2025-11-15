import Foundation

/// Persists a daily entry into the repository.
struct SaveDailyEntryUseCase {
    private let repository: DailyEntryRepository

    init(repository: DailyEntryRepository) {
        self.repository = repository
    }

    func execute(_ entry: DailyEntry) async throws {
        try await repository.save(entry)
    }
}
