import CoreData
import Foundation

/// Implements the `ChallengeRepository` backed by Core Data.
final class CoreDataChallengeRepository: ChallengeRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func fetchAllChallenges() async throws -> [Challenge] {
        try await fetchChallenges(predicate: nil)
    }

    func fetchActiveChallenges() async throws -> [Challenge] {
        let predicate = NSPredicate(format: "startDate <= %@ AND (endDate == nil OR endDate >= %@)", Date() as NSDate, Date() as NSDate)
        return try await fetchChallenges(predicate: predicate)
    }

    func fetchChallenge(with id: UUID) async throws -> Challenge? {
        let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try await stack.container.viewContext.perform {
            try stack.container.viewContext.fetch(request).first.map(ChallengeEntityMapper.map(entity:))
        }
    }

    func save(_ challenge: Challenge) async throws {
        let context = stack.backgroundContext()
        try await context.perform {
            let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? ChallengeEntity(context: context)
            ChallengeEntityMapper.update(entity: entity, from: challenge, in: context)
            try context.save()
        }
    }

    func delete(_ challenge: Challenge) async throws {
        let context = stack.backgroundContext()
        try await context.perform {
            let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", challenge.id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw CoreDataRepositoryError.entityNotFound
            }
            context.delete(entity)
            try context.save()
        }
    }

    private func fetchChallenges(predicate: NSPredicate?) async throws -> [Challenge] {
        let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChallengeEntity.startDate, ascending: false)]
        return try await stack.container.viewContext.perform {
            try stack.container.viewContext.fetch(request).map(ChallengeEntityMapper.map(entity:))
        }
    }
}

private extension ChallengeEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ChallengeEntity> {
        NSFetchRequest<ChallengeEntity>(entityName: "ChallengeEntity")
    }
}
