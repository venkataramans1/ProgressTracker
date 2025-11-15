import Foundation

/// Retrieves all active challenges for display on the dashboard.
struct GetActiveChallengesUseCase {
    private let repository: ChallengeRepository

    init(repository: ChallengeRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Challenge] {
        try await repository.fetchActiveChallenges()
    }
}
