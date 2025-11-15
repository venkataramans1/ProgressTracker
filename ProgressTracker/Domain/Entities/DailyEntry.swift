import Foundation

/// Represents the daily progress log created by the user.
struct DailyEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var notes: String
    var mood: Mood
    var metrics: [String: Double]
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        notes: String = "",
        mood: Mood,
        metrics: [String: Double] = [:],
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.notes = notes
        self.mood = mood
        self.metrics = metrics
        self.isCompleted = isCompleted
    }
}
