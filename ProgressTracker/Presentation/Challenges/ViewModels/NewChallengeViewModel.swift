import Foundation

/// View model powering the multi-step new challenge creation experience.
@MainActor
final class NewChallengeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var detail: String = ""
    @Published var startDate: Date = Date()
    @Published var includeEndDate: Bool = false
    @Published var endDate: Date
    @Published var emoji: String = "🎯"
    @Published var objectives: [ObjectiveDraft]
    @Published var currentStep: Step = .overview
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var savedChallenge: Challenge?

    private let saveChallengeUseCase: SaveChallengeUseCase
    private let calendar: Calendar

    init(
        saveChallengeUseCase: SaveChallengeUseCase,
        calendar: Calendar = .current,
        initialDate: Date = Date()
    ) {
        self.saveChallengeUseCase = saveChallengeUseCase
        self.calendar = calendar
        self.startDate = initialDate
        self.endDate = calendar.date(byAdding: .day, value: 30, to: initialDate) ?? initialDate
        self.objectives = [ObjectiveDraft()]
    }

    var stepIndex: Int {
        Step.allCases.firstIndex(of: currentStep) ?? 0
    }

    var totalSteps: Int {
        Step.allCases.count
    }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(stepIndex + 1) / Double(totalSteps)
    }

    var canAdvanceFromCurrentStep: Bool {
        switch currentStep {
        case .overview:
            return isOverviewValid
        case .objectives:
            return areObjectivesValid
        case .review:
            return canSave
        }
    }

    var canSave: Bool {
        isOverviewValid && areObjectivesValid
    }

    var primaryButtonTitle: String {
        currentStep == .review ? "Create Challenge" : "Next"
    }

    var subtitle: String {
        currentStep.subtitle
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Challenge" : trimmed
    }

    var displayEmoji: String? {
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var detailSummary: String? {
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func advance() {
        guard canAdvanceFromCurrentStep else { return }
        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func goBack() {
        if let previous = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = previous
        }
    }

    func addObjective() {
        objectives.append(ObjectiveDraft())
    }

    func removeObjective(id: ObjectiveDraft.ID) {
        guard objectives.count > 1 else { return }
        objectives.removeAll { $0.id == id }
    }

    func addMilestone(to objectiveID: ObjectiveDraft.ID) {
        guard let index = objectives.firstIndex(where: { $0.id == objectiveID }) else { return }
        objectives[index].milestones.append(MilestoneDraft())
    }

    func removeMilestone(_ milestoneID: MilestoneDraft.ID, from objectiveID: ObjectiveDraft.ID) {
        guard let objectiveIndex = objectives.firstIndex(where: { $0.id == objectiveID }) else { return }
        objectives[objectiveIndex].milestones.removeAll { $0.id == milestoneID }
    }

    func save() async {
        guard canSave, let challenge = makeChallenge() else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await saveChallengeUseCase.execute(challenge)
            savedChallenge = challenge
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func dismissError() {
        errorMessage = nil
    }

    private var isOverviewValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !trimmedTitle.isEmpty
        let validEndDate = !includeEndDate || endDate >= startDate
        return hasTitle && validEndDate
    }

    private var areObjectivesValid: Bool {
        guard !objectives.isEmpty else { return false }
        return objectives.allSatisfy { objective in
            let trimmedTitle = objective.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUnit = objective.unit.trimmingCharacters(in: .whitespacesAndNewlines)
            let milestonesValid = objective.milestones.allSatisfy { milestone in
                !milestone.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return !trimmedTitle.isEmpty && objective.targetValue > 0 && !trimmedUnit.isEmpty && milestonesValid
        }
    }

    private func makeChallenge() -> Challenge? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        let objectives = objectives.map { draft in
            Objective(
                id: draft.id,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                targetValue: draft.targetValue,
                currentValue: 0,
                unit: draft.unit.trimmingCharacters(in: .whitespacesAndNewlines),
                milestones: draft.milestones.map { milestone in
                    Milestone(
                        id: milestone.id,
                        title: milestone.title.trimmingCharacters(in: .whitespacesAndNewlines),
                        targetDate: milestone.targetDate,
                        isCompleted: false
                    )
                }
            )
        }

        return Challenge(
            title: trimmedTitle,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: includeEndDate ? endDate : nil,
            objectives: objectives,
            status: .active,
            emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emoji
        )
    }
}

extension NewChallengeViewModel {
    enum Step: Int, CaseIterable {
        case overview
        case objectives
        case review

        var title: String {
            switch self {
            case .overview: return "Challenge Overview"
            case .objectives: return "Objectives & Milestones"
            case .review: return "Review"
            }
        }

        var subtitle: String {
            switch self {
            case .overview: return "Describe what you want to accomplish."
            case .objectives: return "Break work into measurable objectives with milestones."
            case .review: return "Confirm the plan before saving."
            }
        }
    }

    struct ObjectiveDraft: Identifiable, Hashable {
        let id: UUID
        var title: String
        var targetValue: Double
        var unit: String
        var milestones: [MilestoneDraft]

        init(
            id: UUID = UUID(),
            title: String = "",
            targetValue: Double = 1,
            unit: String = "",
            milestones: [MilestoneDraft] = []
        ) {
            self.id = id
            self.title = title
            self.targetValue = targetValue
            self.unit = unit
            self.milestones = milestones
        }
    }

    struct MilestoneDraft: Identifiable, Hashable {
        let id: UUID
        var title: String
        var targetDate: Date

        init(id: UUID = UUID(), title: String = "", targetDate: Date = Date()) {
            self.id = id
            self.title = title
            self.targetDate = targetDate
        }
    }
}
