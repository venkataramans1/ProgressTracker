import Foundation

/// Handles the presentation logic for viewing and updating a single challenge.
@MainActor
final class ChallengeDetailViewModel: ObservableObject {
    @Published var challenge: Challenge
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var saveSucceeded: Bool = false

    private let saveChallengeUseCase: SaveChallengeUseCase

    init(challenge: Challenge, saveChallengeUseCase: SaveChallengeUseCase) {
        self.challenge = challenge
        self.saveChallengeUseCase = saveChallengeUseCase
    }

    func toggleMilestone(_ milestone: Milestone, in objective: Objective) {
        guard let objectiveIndex = challenge.objectives.firstIndex(where: { $0.id == objective.id }) else { return }
        guard let milestoneIndex = challenge.objectives[objectiveIndex].milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
        challenge.objectives[objectiveIndex].milestones[milestoneIndex].isCompleted.toggle()
        Task { await save() }
    }

    func save() async {
        isSaving = true
        errorMessage = nil
        saveSucceeded = false
        do {
            try await saveChallengeUseCase.execute(challenge)
            saveSucceeded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
