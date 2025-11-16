import Foundation
import SwiftUI

/// Handles presentation logic for the merged dashboard and daily log experience.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedDate: Date
    @Published var expandedChallengeID: UUID?
    @Published var statusFilter: ChallengeStatusFilter = .all
    @Published private(set) var challengeItems: [ChallengeItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var mood: Mood = .average

    var filteredChallenges: [ChallengeItem] {
        switch statusFilter {
        case .all:
            return challengeItems
        case .completed:
            return challengeItems.filter { $0.detail.isCompleted }
        case .notStarted:
            return challengeItems.filter { !$0.detail.isCompleted }
        }
    }

    private var currentEntry: DailyEntry?
    private let getActiveChallengesUseCase: GetActiveChallengesUseCase
    private let dailyEntryRepository: DailyEntryRepository
    private let saveDailyEntryUseCase: SaveDailyEntryUseCase
    private let calendar: Calendar

    init(
        getActiveChallengesUseCase: GetActiveChallengesUseCase,
        dailyEntryRepository: DailyEntryRepository,
        saveDailyEntryUseCase: SaveDailyEntryUseCase,
        calendar: Calendar = .current,
        initialDate: Date = Date()
    ) {
        self.getActiveChallengesUseCase = getActiveChallengesUseCase
        self.dailyEntryRepository = dailyEntryRepository
        self.saveDailyEntryUseCase = saveDailyEntryUseCase
        self.calendar = calendar
        self.selectedDate = initialDate

        Task { await load(for: initialDate) }
    }

    func setSelectedDate(_ date: Date) {
        guard !calendar.isDate(date, inSameDayAs: selectedDate) else { return }
        selectedDate = date
        Task { await load(for: date) }
    }

    func toggleExpansion(for challengeID: UUID) {
        withAnimation {
            expandedChallengeID = expandedChallengeID == challengeID ? nil : challengeID
        }
    }

    func toggleCompletion(for challengeID: UUID) async {
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        challengeItems[index].detail.isCompleted.toggle()
        await persistChanges()
    }

    func update(detail: ChallengeDetail, for challengeID: UUID, mood: Mood) async {
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        challengeItems[index].detail = detail
        self.mood = mood
        await persistChanges()
    }

    func updateMood(_ mood: Mood) {
        guard self.mood != mood else { return }
        self.mood = mood
        Task { await persistChanges() }
    }

    func refresh() async {
        await load(for: selectedDate)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func load(for date: Date) async {
        isLoading = true
        errorMessage = nil
        do {
            async let challengesTask = getActiveChallengesUseCase.execute()
            async let entryTask = dailyEntryRepository.fetchEntry(for: date)
            let challenges = try await challengesTask
            let entry = try await entryTask
            currentEntry = entry
            mood = entry?.resolvedMood ?? .average
            expandedChallengeID = nil
            challengeItems = challenges.map { challenge in
                let detail = entry?.challengeDetails.first { $0.challengeId == challenge.id } ?? ChallengeDetail(challengeId: challenge.id)
                return ChallengeItem(challenge: challenge, detail: detail)
            }
        } catch {
            errorMessage = error.localizedDescription
            challengeItems = []
        }
        isLoading = false
    }

    private func persistChanges() async {
        isSaving = true
        errorMessage = nil
        let entry = DailyEntry(
            id: currentEntry?.id ?? UUID(),
            date: selectedDate,
            mood: mood,
            challengeDetails: challengeItems.map { $0.detail },
            editedAt: Date()
        )
        do {
            try await saveDailyEntryUseCase.execute(entry)
            currentEntry = entry
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

extension DashboardViewModel {
    enum ChallengeStatusFilter: String, CaseIterable, Identifiable {
        case all
        case completed
        case notStarted

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .completed: return "Completed"
            case .notStarted: return "Not Started"
            }
        }
    }

    struct ChallengeItem: Identifiable, Equatable {
        let challenge: Challenge
        var detail: ChallengeDetail

        var id: UUID { challenge.id }
        var emoji: String { challenge.emoji ?? "🎯" }
        var title: String { challenge.title }
        var subtitle: String { challenge.detail }
        var statusText: String { detail.isCompleted ? "Completed" : "Not Started" }
    }
}
