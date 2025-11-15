import Combine
import Foundation

/// Handles presentation logic for the dashboard screen.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var activeChallenges: [Challenge] = []
    @Published private(set) var streakCount: Int = 0
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    var overallProgress: Double {
        guard !activeChallenges.isEmpty else { return 0 }
        let total = activeChallenges.reduce(0) { $0 + $1.progress }
        return total / Double(activeChallenges.count)
    }

    private let getActiveChallengesUseCase: GetActiveChallengesUseCase
    private let calculateStreakUseCase: CalculateStreakUseCase

    init(
        getActiveChallengesUseCase: GetActiveChallengesUseCase,
        calculateStreakUseCase: CalculateStreakUseCase
    ) {
        self.getActiveChallengesUseCase = getActiveChallengesUseCase
        self.calculateStreakUseCase = calculateStreakUseCase
        Task { await load() }
    }

    /// Loads active challenges and streak information.
    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let challenges = getActiveChallengesUseCase.execute()
            async let streak = calculateStreakUseCase.execute()
            activeChallenges = try await challenges
            streakCount = try await streak
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
