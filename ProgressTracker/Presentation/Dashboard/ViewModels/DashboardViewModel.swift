import Foundation
import SwiftUI

/// Handles presentation logic for the merged dashboard and daily log experience.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var currentDate: Date
    @Published var expandedChallengeID: UUID?
    @Published var statusFilter: ChallengeStatusFilter = .all
    @Published private(set) var challengeItems: [ChallengeItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?

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
    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

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
        let normalized = calendar.startOfDay(for: initialDate)
        self.currentDate = normalized

        Task { await load(for: normalized) }
    }

    func toggleExpansion(for challengeID: UUID) {
        withAnimation {
            expandedChallengeID = expandedChallengeID == challengeID ? nil : challengeID
        }
    }

    func toggleCompletion(for challengeID: UUID) async {
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        var detail = challengeItems[index].detail
        let challenge = challengeItems[index].challenge
        detail.isCompleted.toggle()
        if detail.isCompleted && challenge.trackingStyle == .trackTime {
            if let target = challenge.dailyTargetMinutes, target > 0, detail.loggedMinutes == 0 {
                detail.loggedMinutes = target
            }
        }
        challengeItems[index].detail = detail
        await persistChanges()
    }

    func logMinutes(_ minutes: Int, for challengeID: UUID) async {
        guard minutes > 0 else { return }
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        guard challengeItems[index].challenge.trackingStyle == .trackTime else { return }
        challengeItems[index].detail.loggedMinutes += minutes
        recomputeCompletionIfNeeded(for: index)
        await persistChanges()
    }

    func setLoggedMinutes(_ totalMinutes: Int, for challengeID: UUID) async {
        guard totalMinutes >= 0 else { return }
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        guard challengeItems[index].challenge.trackingStyle == .trackTime else { return }
        challengeItems[index].detail.loggedMinutes = totalMinutes
        recomputeCompletionIfNeeded(for: index)
        await persistChanges()
    }

    func update(detail: ChallengeDetail, for challengeID: UUID) async {
        guard let index = challengeItems.firstIndex(where: { $0.id == challengeID }) else { return }
        challengeItems[index].detail = detail
        await persistChanges()
    }

    func refresh() async {
        await load(for: Date())
    }

    func dismissError() {
        errorMessage = nil
    }

    private func load(for date: Date) async {
        let normalizedDate = calendar.startOfDay(for: date)
        isLoading = true
        errorMessage = nil
        do {
            async let challengesTask = getActiveChallengesUseCase.execute()
            async let entryTask = dailyEntryRepository.fetchEntry(for: normalizedDate)
            let challenges = try await challengesTask
            let entry = try await entryTask
            currentEntry = entry
            currentDate = normalizedDate
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
            date: currentDate,
            mood: currentEntry?.mood,
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

    private func recomputeCompletionIfNeeded(for index: Int) {
        let challenge = challengeItems[index].challenge
        guard challenge.trackingStyle == .trackTime,
              let target = challenge.dailyTargetMinutes,
              target > 0 else { return }
        challengeItems[index].detail.isCompleted = challengeItems[index].detail.loggedMinutes >= target
    }

    var dateHeaderText: String {
        let formatted = Self.headerFormatter.string(from: currentDate)
        return "Today, \(formatted)"
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
        var statusText: String {
            if detail.isCompleted { return "Completed" }
            if trackingStyle == .trackTime, detail.loggedMinutes > 0 {
                return "In progress - \(detail.loggedMinutes) min"
            }
            return "Not started"
        }
        var trackingStyle: Challenge.TrackingStyle { challenge.trackingStyle }
        var targetMinutes: Int? { challenge.dailyTargetMinutes }
        var loggedMinutes: Int { detail.loggedMinutes }

        var timeSummaryLine: String {
            if let targetMinutes {
                return "Logged today: \(loggedMinutes) min | Target: \(targetMinutes) min"
            }
            return "Logged today: \(loggedMinutes) min"
        }
    }
}
