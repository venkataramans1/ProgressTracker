import CoreData
import Foundation

struct ChallengeDetailEntityMapper {
    static func map(entity: ChallengeDetailEntity) -> ChallengeDetail {
        let storedPhotoStrings = entity.photoURLs as? [String] ?? []
        let photoURLs = storedPhotoStrings.compactMap { string -> URL? in
            if let url = URL(string: string), url.scheme != nil {
                return url
            }
            return URL(fileURLWithPath: string)
        }
        let tags = entity.tags as? [String] ?? []
        return ChallengeDetail(
            id: entity.id,
            challengeId: entity.challengeId,
            isCompleted: entity.isCompleted,
            loggedMinutes: entity.loggedMinutes?.intValue ?? 0,
            notes: entity.notes,
            photoURLs: photoURLs,
            tags: tags
        )
    }

    @discardableResult
    static func update(entity: ChallengeDetailEntity, from detail: ChallengeDetail, entry: DailyEntryEntity) -> ChallengeDetailEntity {
        entity.id = detail.id
        entity.challengeId = detail.challengeId
        entity.isCompleted = detail.isCompleted
        entity.loggedMinutes = NSNumber(value: detail.loggedMinutes)
        entity.notes = detail.notes
        entity.photoURLs = detail.photoURLs.map { $0.absoluteString } as NSArray
        entity.tags = detail.tags as NSArray
        entity.dailyEntry = entry
        return entity
    }
}
