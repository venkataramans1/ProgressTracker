import CoreData
import Foundation

@objc(ObjectiveEntity)
final class ObjectiveEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var targetValue: Double
    @NSManaged var currentValue: Double
    @NSManaged var unit: String
    @NSManaged var challenge: ChallengeEntity
    @NSManaged var milestones: NSSet?
}
