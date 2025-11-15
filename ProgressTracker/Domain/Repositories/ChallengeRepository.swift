import Foundation

/// Defines operations related to retrieving and mutating challenges.
protocol ChallengeRepository {
    func fetchAllChallenges() async throws -> [Challenge]
    func fetchActiveChallenges() async throws -> [Challenge]
    func fetchChallenge(with id: UUID) async throws -> Challenge?
    func save(_ challenge: Challenge) async throws
    func delete(_ challenge: Challenge) async throws
}
