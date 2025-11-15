import Foundation

/// Removes a daily entry from the repository.
struct DeleteDailyEntryUseCase {
    private let repository: DailyEntryRepository

    init(repository: DailyEntryRepository) {
        self.repository = repository
    }

    func execute(_ entry: DailyEntry) async throws {
        try await repository.delete(entry)
    }
}
