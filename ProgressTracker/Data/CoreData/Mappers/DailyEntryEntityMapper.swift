import CoreData
import Foundation

struct DailyEntryEntityMapper {
    static func map(entity: DailyEntryEntity) -> DailyEntry {
        let moodValue = entity.mood.flatMap { Mood(rawValue: $0) }
        let details = (entity.challengeDetails as? Set<ChallengeDetailEntity>)?
            .map { ChallengeDetailEntityMapper.map(entity: $0) }
            .sorted { $0.id.uuidString < $1.id.uuidString } ?? []
        return DailyEntry(
            id: entity.id,
            date: entity.date,
            mood: moodValue,
            challengeDetails: details,
            editedAt: entity.editedAt
        )
    }

    static func update(entity: DailyEntryEntity, from entry: DailyEntry, in context: NSManagedObjectContext) {
        entity.id = entry.id
        entity.date = entry.date
        entity.mood = entry.mood?.rawValue
        entity.editedAt = entry.editedAt

        let existingDetails = entity.challengeDetails as? Set<ChallengeDetailEntity> ?? []
        existingDetails.forEach(context.delete)

        let detailEntities = entry.challengeDetails.map { detail -> ChallengeDetailEntity in
            let detailEntity = ChallengeDetailEntity(context: context)
            return ChallengeDetailEntityMapper.update(entity: detailEntity, from: detail, entry: entity)
        }
        entity.challengeDetails = NSSet(array: detailEntities)
    }
}
