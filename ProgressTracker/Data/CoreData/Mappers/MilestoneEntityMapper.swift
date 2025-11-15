import CoreData
import Foundation

/// Maps Core Data `MilestoneEntity` objects into domain `Milestone` models and vice versa.
struct MilestoneEntityMapper {
    static func map(entity: MilestoneEntity) -> Milestone {
        Milestone(
            id: entity.id,
            title: entity.title,
            targetDate: entity.targetDate,
            isCompleted: entity.isCompleted
        )
    }

    @discardableResult
    static func update(entity: MilestoneEntity, from milestone: Milestone, objective: ObjectiveEntity) -> MilestoneEntity {
        entity.id = milestone.id
        entity.title = milestone.title
        entity.targetDate = milestone.targetDate
        entity.isCompleted = milestone.isCompleted
        entity.objective = objective
        return entity
    }
}
