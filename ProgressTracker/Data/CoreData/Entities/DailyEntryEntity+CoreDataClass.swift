import CoreData
import Foundation

@objc(DailyEntryEntity)
final class DailyEntryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var mood: String?
    @NSManaged var editedAt: Date?
    @NSManaged var challengeDetails: NSSet?
}
