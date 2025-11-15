import Foundation

/// Handles retrieving and presenting a list of challenges.
@MainActor
final class ChallengesListViewModel: ObservableObject {
    @Published private(set) var challenges: [Challenge] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let getChallengesUseCase: GetChallengesUseCase

    init(getChallengesUseCase: GetChallengesUseCase) {
        self.getChallengesUseCase = getChallengesUseCase
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            challenges = try await getChallengesUseCase.execute().sorted { $0.startDate > $1.startDate }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
