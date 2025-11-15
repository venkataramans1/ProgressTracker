import Foundation

/// Represents an actionable objective tied to a challenge.
struct Objective: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var milestones: [Milestone]

    init(
        id: UUID = UUID(),
        title: String,
        targetValue: Double,
        currentValue: Double = 0,
        unit: String,
        milestones: [Milestone] = []
    ) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.milestones = milestones
    }

    /// Returns the progress for the objective between 0 and 1.
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1)
    }
}
