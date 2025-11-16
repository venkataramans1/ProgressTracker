import Foundation

protocol ChallengeRepository {
    func fetchAllChallenges() async throws -> [Challenge]
    func fetchActiveChallenges() async throws -> [Challenge]
    func fetchChallenges(with status: Challenge.Status) async throws -> [Challenge]
    func fetchChallenge(with id: UUID) async throws -> Challenge?
    func save(_ challenge: Challenge) async throws
    func delete(_ challenge: Challenge) async throws
    func storePhoto(at url: URL) throws -> URL
    func deletePhoto(at url: URL) throws
}
