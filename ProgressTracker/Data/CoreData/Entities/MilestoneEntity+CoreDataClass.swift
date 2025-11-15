import CoreData
import Foundation

@objc(MilestoneEntity)
final class MilestoneEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var targetDate: Date
    @NSManaged var isCompleted: Bool
    @NSManaged var objective: ObjectiveEntity
}
