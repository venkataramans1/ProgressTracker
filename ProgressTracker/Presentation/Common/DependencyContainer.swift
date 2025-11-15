import Foundation

/// Simple dependency container that wires repositories, use cases and services together.
final class DependencyContainer: ObservableObject {
    let challengeRepository: ChallengeRepository
    let dailyEntryRepository: DailyEntryRepository

    let getActiveChallengesUseCase: GetActiveChallengesUseCase
    let getChallengesUseCase: GetChallengesUseCase
    let saveChallengeUseCase: SaveChallengeUseCase
    let getDailyEntriesUseCase: GetDailyEntriesUseCase
    let saveDailyEntryUseCase: SaveDailyEntryUseCase
    let deleteDailyEntryUseCase: DeleteDailyEntryUseCase
    let calculateStreakUseCase: CalculateStreakUseCase
    let generateInsightsUseCase: GenerateInsightsUseCase

    private let sampleDataService: SampleDataService

    init(stack: CoreDataStack = .shared) {
        let challengeRepository = CoreDataChallengeRepository(stack: stack)
        let dailyEntryRepository = CoreDataDailyEntryRepository(stack: stack)

        self.challengeRepository = challengeRepository
        self.dailyEntryRepository = dailyEntryRepository

        getActiveChallengesUseCase = GetActiveChallengesUseCase(repository: challengeRepository)
        getChallengesUseCase = GetChallengesUseCase(repository: challengeRepository)
        saveChallengeUseCase = SaveChallengeUseCase(repository: challengeRepository)
        getDailyEntriesUseCase = GetDailyEntriesUseCase(repository: dailyEntryRepository)
        saveDailyEntryUseCase = SaveDailyEntryUseCase(repository: dailyEntryRepository)
        deleteDailyEntryUseCase = DeleteDailyEntryUseCase(repository: dailyEntryRepository)
        calculateStreakUseCase = CalculateStreakUseCase(repository: dailyEntryRepository)
        generateInsightsUseCase = GenerateInsightsUseCase(repository: dailyEntryRepository)

        sampleDataService = SampleDataService(
            challengeRepository: challengeRepository,
            entryRepository: dailyEntryRepository
        )

        Task {
            await sampleDataService.populateIfNeeded()
        }
    }
}
