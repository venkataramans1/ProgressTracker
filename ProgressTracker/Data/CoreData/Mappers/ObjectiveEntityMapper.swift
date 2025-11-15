import CoreData
import Foundation

/// Maps Core Data `ObjectiveEntity` objects into domain `Objective` models and vice versa.
struct ObjectiveEntityMapper {
    static func map(entity: ObjectiveEntity) -> Objective {
        let milestones = (entity.milestones as? Set<MilestoneEntity>)?
            .map(MilestoneEntityMapper.map(entity:))
            .sorted { $0.targetDate < $1.targetDate } ?? []
        return Objective(
            id: entity.id,
            title: entity.title,
            targetValue: entity.targetValue,
            currentValue: entity.currentValue,
            unit: entity.unit,
            milestones: milestones
        )
    }

    @discardableResult
    static func update(
        entity: ObjectiveEntity,
        from objective: Objective,
        challenge: ChallengeEntity,
        in context: NSManagedObjectContext
    ) -> ObjectiveEntity {
        entity.id = objective.id
        entity.title = objective.title
        entity.targetValue = objective.targetValue
        entity.currentValue = objective.currentValue
        entity.unit = objective.unit
        entity.challenge = challenge

        let existingMilestones = entity.milestones as? Set<MilestoneEntity> ?? []
        existingMilestones.forEach(context.delete)

        let newMilestoneEntities = objective.milestones.map { milestone in
            let milestoneEntity = MilestoneEntity(context: context)
            return MilestoneEntityMapper.update(entity: milestoneEntity, from: milestone, objective: entity)
        }
        entity.milestones = NSSet(array: newMilestoneEntities)
        return entity
    }
}
