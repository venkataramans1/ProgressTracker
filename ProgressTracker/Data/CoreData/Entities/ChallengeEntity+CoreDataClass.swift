import CoreData
import Foundation

@objc(ChallengeEntity)
final class ChallengeEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var detail: String?
    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?
    @NSManaged var objectives: NSSet?
}
