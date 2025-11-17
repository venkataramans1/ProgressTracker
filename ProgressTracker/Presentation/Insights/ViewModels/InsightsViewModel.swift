import Foundation

/// Represents aggregated analytics data for the insights charts.
struct InsightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let focusHours: Double
    let moodScore: Double
    let completionRate: Double
}

/// Summary information for the resilience section.
struct ResilienceSummary {
    enum Trend {
        case improving
        case steady
        case declining
    }

    let averageMood: Double
    let averageFocusHours: Double
    let completionRate: Double
    let activeChallenges: Int
    let currentStreak: Int
    let resilienceScore: Double
    let trend: Trend

    var completionPercentage: Double { completionRate * 100 }
}

/// Represents an actionable nudge surfaced from the insights pipeline.
struct ResilienceNudge: Identifiable, Equatable {
    enum Kind {
        case mindfulness
        case focus
        case movement
        case celebration
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let detail: String
}

struct ChallengeInsight: Identifiable, Equatable {
    let id: UUID
    let title: String
    let checkIns: Int
    let completionRate: Double
    let lastUpdated: Date?
}

/// Handles retrieving and presenting insight analytics.
@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var dataPoints: [InsightDataPoint] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var summary: ResilienceSummary?
    @Published private(set) var nudges: [ResilienceNudge] = []
    @Published private(set) var challengeInsights: [ChallengeInsight] = []

    private let generateInsightsUseCase: GenerateInsightsUseCase
    private let getChallengesUseCase: GetChallengesUseCase
    private let notificationService: LocalNotificationService
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let lastNudgeDateKey = "insights.lastNudgeDate"

    init(
        generateInsightsUseCase: GenerateInsightsUseCase,
        getChallengesUseCase: GetChallengesUseCase,
        notificationService: LocalNotificationService = .shared,
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.generateInsightsUseCase = generateInsightsUseCase
        self.getChallengesUseCase = getChallengesUseCase
        self.notificationService = notificationService
        self.userDefaults = userDefaults
        self.calendar = calendar
        Task { await load() }
    }

    func load(days: Int = 14) async {
        isLoading = true
        errorMessage = nil
        do {
            async let entriesTask = generateInsightsUseCase.execute(forDays: days)
            async let challengesTask = getChallengesUseCase.execute()
            let entries = try await entriesTask
            let challenges = try await challengesTask
            dataPoints = entries
                .sorted { $0.date < $1.date }
                .map { entry in
                    let focus = entry.metrics["Focus (hrs)"] ?? 0
                    let moodScore = Self.moodScore(for: entry.resolvedMood)
                    let completion = Self.completionRate(for: entry)
                    return InsightDataPoint(
                        date: entry.date,
                        focusHours: focus,
                        moodScore: moodScore,
                        completionRate: completion
                    )
                }
            summary = makeSummary(from: dataPoints, entries: entries)
            challengeInsights = makeChallengeInsights(from: entries, challenges: challenges)
            let summaryNudges = summary.map { buildSummaryNudges(from: $0) } ?? []
            let challengeNudges = buildChallengeNudges(from: challengeInsights)
            nudges = Array((summaryNudges + challengeNudges).prefix(3))
            scheduleNudgeIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private static func moodScore(for mood: Mood) -> Double {
        switch mood {
        case .excellent: return 5
        case .good: return 4
        case .average: return 3
        case .low: return 2
        case .bad: return 1
        }
    }

    private static func completionRate(for entry: DailyEntry) -> Double {
        guard !entry.challengeDetails.isEmpty else { return 0 }
        let completed = entry.challengeDetails.filter { $0.isCompleted }.count
        return Double(completed) / Double(entry.challengeDetails.count)
    }

    private func makeSummary(from points: [InsightDataPoint], entries: [DailyEntry]) -> ResilienceSummary? {
        guard !points.isEmpty else { return nil }
        let moodAverage = points.map { $0.moodScore }.average()
        let focusAverage = points.map { $0.focusHours }.average()
        let completionAverage = points.map { $0.completionRate }.average()
        let uniqueChallenges = Set(entries.flatMap { $0.challengeDetails.map { $0.challengeId } })
        let streak = currentStreak(from: entries)
        let score = Self.resilienceScore(
            mood: moodAverage,
            focus: focusAverage,
            completion: completionAverage,
            streak: streak
        )
        let trend = calculateTrend(from: points)
        return ResilienceSummary(
            averageMood: moodAverage,
            averageFocusHours: focusAverage,
            completionRate: completionAverage,
            activeChallenges: uniqueChallenges.count,
            currentStreak: streak,
            resilienceScore: score,
            trend: trend
        )
    }

    private static func resilienceScore(
        mood: Double,
        focus: Double,
        completion: Double,
        streak: Int
    ) -> Double {
        let normalizedMood = mood / 5.0
        let normalizedFocus = min(focus / 4.0, 1)
        let streakComponent = min(Double(streak) / 7.0, 1)
        let score = (normalizedMood + normalizedFocus + completion + streakComponent) / 4.0
        return score * 100
    }

    private static func resilienceScore(for point: InsightDataPoint) -> Double {
        let normalizedMood = point.moodScore / 5.0
        let normalizedFocus = min(point.focusHours / 4.0, 1)
        let score = (normalizedMood + normalizedFocus + point.completionRate) / 3.0
        return score * 100
    }

    private func currentStreak(from entries: [DailyEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        let sorted = entries.sorted { $0.date > $1.date }
        guard let latest = sorted.first else { return 0 }
        if !calendar.isDateInToday(latest.date) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
            if let yesterday, !calendar.isDate(latest.date, inSameDayAs: yesterday) {
                return 0
            }
        }
        var streak = 1
        var previousDate = latest.date
        for entry in sorted.dropFirst() {
            let diff = calendar.dateComponents([.day], from: entry.date, to: previousDate).day ?? 0
            if diff == 0 {
                continue
            } else if diff == 1 {
                streak += 1
                previousDate = entry.date
            } else {
                break
            }
        }
        return streak
    }

    private func calculateTrend(from points: [InsightDataPoint]) -> ResilienceSummary.Trend {
        guard points.count >= 4 else { return .steady }
        let recentSlice = points.suffix(3)
        let previousSlice = points.dropLast(3).suffix(3)
        guard !previousSlice.isEmpty else { return .steady }
        let recentScore = recentSlice.map { Self.resilienceScore(for: $0) }.average()
        let previousScore = previousSlice.map { Self.resilienceScore(for: $0) }.average()
        let delta = recentScore - previousScore
        if delta > 5 {
            return .improving
        } else if delta < -5 {
            return .declining
        }
        return .steady
    }

    private func buildSummaryNudges(from summary: ResilienceSummary) -> [ResilienceNudge] {
        var recommendations: [ResilienceNudge] = []
        if summary.averageFocusHours < 2 {
            recommendations.append(
                ResilienceNudge(
                    kind: .focus,
                    title: "Protect your focus",
                    detail: "Deep work averages \(summary.averageFocusHours.formatted(.number.precision(.fractionLength(1))))h. Block a focus sprint today."
                )
            )
        }
        if summary.currentStreak >= 5 {
            recommendations.append(
                ResilienceNudge(
                    kind: .celebration,
                    title: "Streak hero",
                    detail: "You've logged \(summary.currentStreak) days in a row. Celebrate the streak!"
                )
            )
        }
        if summary.resilienceScore < 55 {
            recommendations.append(
                ResilienceNudge(
                    kind: .mindfulness,
                    title: "Mindful pause",
                    detail: "Resilience dipped to \(Int(summary.resilienceScore)). Take 5 minutes to reset."
                )
            )
        }
        return recommendations
    }

    private func makeChallengeInsights(from entries: [DailyEntry], challenges: [Challenge]) -> [ChallengeInsight] {
        let challengeLookup = Dictionary(uniqueKeysWithValues: challenges.map { ($0.id, $0.title) })
        var aggregates: [UUID: (title: String, hits: Int, completed: Int, lastDate: Date?)] = [:]

        for entry in entries {
            for detail in entry.challengeDetails {
                let title = challengeLookup[detail.challengeId] ?? "Challenge"
                var data = aggregates[detail.challengeId, default: (title, 0, 0, nil)]
                data.hits += 1
                if detail.isCompleted { data.completed += 1 }
                if let existing = data.lastDate {
                    data.lastDate = max(existing, entry.date)
                } else {
                    data.lastDate = entry.date
                }
                aggregates[detail.challengeId] = data
            }
        }

        return aggregates.map { id, value in
            let rate = value.hits == 0 ? 0 : Double(value.completed) / Double(value.hits)
            return ChallengeInsight(
                id: id,
                title: value.title,
                checkIns: value.hits,
                completionRate: rate,
                lastUpdated: value.lastDate
            )
        }
        .sorted { $0.checkIns > $1.checkIns }
    }

    private func buildChallengeNudges(from insights: [ChallengeInsight]) -> [ResilienceNudge] {
        guard let lowCompletion = insights.first(where: { $0.completionRate < 0.5 }) else { return [] }
        return [
            ResilienceNudge(
                kind: .focus,
                title: "Revisit \(lowCompletion.title)",
                detail: "Completion is at \(lowCompletion.completionRate.formatted(.percent.precision(.fractionLength(0)))) — consider breaking the next milestone into smaller wins."
            )
        ]
    }

    private func scheduleNudgeIfNeeded() {
        guard let message = nudges.first?.title else { return }
        if let lastDate = userDefaults.object(forKey: lastNudgeDateKey) as? Date,
           calendar.isDate(lastDate, inSameDayAs: Date()) {
            return
        }
        userDefaults.set(Date(), forKey: lastNudgeDateKey)
        notificationService.scheduleResilienceNudge(message: message)
    }
}

private extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        let total = reduce(0, +)
        return total / Double(count)
    }
}
