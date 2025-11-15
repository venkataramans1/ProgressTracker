import CoreData
import Foundation

@objc(DailyEntryEntity)
final class DailyEntryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var notes: String?
    @NSManaged var mood: String
    @NSManaged var metrics: NSDictionary?
    @NSManaged var isCompleted: Bool
}
