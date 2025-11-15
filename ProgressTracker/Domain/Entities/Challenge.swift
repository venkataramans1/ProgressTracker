import Foundation

/// Represents a long-term challenge that contains several objectives.
struct Challenge: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var startDate: Date
    var endDate: Date?
    var objectives: [Objective]

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        startDate: Date,
        endDate: Date? = nil,
        objectives: [Objective] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.startDate = startDate
        self.endDate = endDate
        self.objectives = objectives
    }

    /// Indicates whether the challenge is active relative to the current date.
    var isActive: Bool {
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }

    /// Calculates the overall progress by averaging the progress of all objectives.
    var progress: Double {
        guard !objectives.isEmpty else { return 0 }
        let total = objectives.reduce(0) { $0 + $1.progress }
        return total / Double(objectives.count)
    }
}
