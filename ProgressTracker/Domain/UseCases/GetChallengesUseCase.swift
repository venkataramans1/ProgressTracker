import Foundation

/// Retrieves all challenges for listing screens.
struct GetChallengesUseCase {
    private let repository: ChallengeRepository

    init(repository: ChallengeRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Challenge] {
        try await repository.fetchAllChallenges()
    }
}
