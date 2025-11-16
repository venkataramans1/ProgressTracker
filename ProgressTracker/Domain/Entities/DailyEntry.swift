import Foundation

struct DailyEntry: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var date: Date
    var mood: Mood?
    var challengeDetails: [ChallengeDetail]
    var editedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date,
        mood: Mood? = nil,
        challengeDetails: [ChallengeDetail] = [],
        editedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.challengeDetails = challengeDetails
        self.editedAt = editedAt
    }
}
