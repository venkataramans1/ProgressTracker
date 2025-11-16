import Foundation

protocol DailyEntryRepository {
    func fetchEntries(startingFrom startDate: Date, to endDate: Date) async throws -> [DailyEntry]
    func fetchEntry(for date: Date) async throws -> DailyEntry?
    func save(_ entry: DailyEntry) async throws
    func delete(_ entry: DailyEntry) async throws
    func checkDuplicateEntry(for date: Date) async throws -> Bool
}
