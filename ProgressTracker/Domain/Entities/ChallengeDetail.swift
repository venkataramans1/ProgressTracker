import Foundation

struct ChallengeDetail: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var challengeId: UUID
    var isCompleted: Bool
    var notes: String?
    var photoURLs: [URL]
    var tags: [String]

    init(
        id: UUID = UUID(),
        challengeId: UUID,
        isCompleted: Bool = false,
        notes: String? = nil,
        photoURLs: [URL] = [],
        tags: [String] = []
    ) {
        self.id = id
        self.challengeId = challengeId
        self.isCompleted = isCompleted
        self.notes = notes
        self.photoURLs = photoURLs
        self.tags = tags
    }
}
