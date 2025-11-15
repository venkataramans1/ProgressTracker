import Foundation

/// Represents a milestone within a larger objective of a challenge.
struct Milestone: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var targetDate: Date
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, targetDate: Date, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.isCompleted = isCompleted
    }
}
