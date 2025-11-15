import Foundation

/// Represents aggregated analytics data for the insights charts.
struct InsightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let focusHours: Double
    let exerciseMinutes: Double
    let moodScore: Double
}

/// Handles retrieving and presenting insight analytics.
@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var dataPoints: [InsightDataPoint] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let generateInsightsUseCase: GenerateInsightsUseCase

    init(generateInsightsUseCase: GenerateInsightsUseCase) {
        self.generateInsightsUseCase = generateInsightsUseCase
        Task { await load() }
    }

    func load(days: Int = 14) async {
        isLoading = true
        errorMessage = nil
        do {
            let entries = try await generateInsightsUseCase.execute(forDays: days)
            dataPoints = entries.sorted { $0.date < $1.date }.map { entry in
                let focus = entry.metrics["Focus (hrs)"] ?? 0
                let exercise = entry.metrics["Exercise (mins)"] ?? 0
                let moodScore = Self.moodScore(for: entry.mood)
                return InsightDataPoint(date: entry.date, focusHours: focus, exerciseMinutes: exercise, moodScore: moodScore)
            }
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
}
