import CoreData
import Foundation

@objc(ChallengeDetailEntity)
final class ChallengeDetailEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var challengeId: UUID
    @NSManaged var isCompleted: Bool
    @NSManaged var notes: String?
    @NSManaged var photoURLs: NSArray?
    @NSManaged var tags: NSArray?
    @NSManaged var dailyEntry: DailyEntryEntity
}
