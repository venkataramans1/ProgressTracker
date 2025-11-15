import Foundation

/// Persists a challenge and its objectives/milestones.
struct SaveChallengeUseCase {
    private let repository: ChallengeRepository

    init(repository: ChallengeRepository) {
        self.repository = repository
    }

    func execute(_ challenge: Challenge) async throws {
        try await repository.save(challenge)
    }
}
