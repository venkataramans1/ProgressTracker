import CoreData
import Foundation

/// Maps Core Data `ChallengeEntity` objects into domain `Challenge` models and vice versa.
struct ChallengeEntityMapper {
    static func map(entity: ChallengeEntity) -> Challenge {
        let objectives = (entity.objectives as? Set<ObjectiveEntity>)?
            .map(ObjectiveEntityMapper.map(entity:))
            .sorted { $0.title < $1.title } ?? []
        return Challenge(
            id: entity.id,
            title: entity.title,
            detail: entity.detail ?? "",
            startDate: entity.startDate,
            endDate: entity.endDate,
            objectives: objectives
        )
    }

    @discardableResult
    static func update(entity: ChallengeEntity, from challenge: Challenge, in context: NSManagedObjectContext) -> ChallengeEntity {
        entity.id = challenge.id
        entity.title = challenge.title
        entity.detail = challenge.detail
        entity.startDate = challenge.startDate
        entity.endDate = challenge.endDate

        let existingObjectives = entity.objectives as? Set<ObjectiveEntity> ?? []
        existingObjectives.forEach(context.delete)

        let newObjectiveEntities = challenge.objectives.map { objective in
            let objectiveEntity = ObjectiveEntity(context: context)
            return ObjectiveEntityMapper.update(entity: objectiveEntity, from: objective, challenge: entity, in: context)
        }
        entity.objectives = NSSet(array: newObjectiveEntities)
        return entity
    }
}
