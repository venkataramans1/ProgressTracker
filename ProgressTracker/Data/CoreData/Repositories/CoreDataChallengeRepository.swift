import CoreData
import Foundation

final class CoreDataChallengeRepository: ChallengeRepository {
    private let stack: CoreDataStack
    private let photoStorage: PhotoStoring

    init(stack: CoreDataStack = .shared, photoStorage: PhotoStoring = DefaultPhotoStorage()) {
        self.stack = stack
        self.photoStorage = photoStorage
    }

    func fetchAllChallenges() async throws -> [Challenge] {
        try await fetchChallenges(predicate: nil)
    }

    func fetchActiveChallenges() async throws -> [Challenge] {
        try await fetchChallenges(with: .active)
    }

    func fetchChallenges(with status: Challenge.Status) async throws -> [Challenge] {
        let predicate = NSPredicate(format: "status == %@", status.rawValue)
        return try await fetchChallenges(predicate: predicate)
    }

    func fetchChallenge(with id: UUID) async throws -> Challenge? {
        let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try await stack.container.viewContext.perform {
            try self.stack.container.viewContext.fetch(request).first.map(ChallengeEntityMapper.map(entity:))
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

    func storePhoto(at url: URL) throws -> URL {
        try photoStorage.persistIfNeeded(url: url)
    }

    func deletePhoto(at url: URL) throws {
        try photoStorage.remove(url: url)
    }

    private func fetchChallenges(predicate: NSPredicate?) async throws -> [Challenge] {
        let request: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChallengeEntity.startDate, ascending: false)]
        return try await stack.container.viewContext.perform {
            try self.stack.container.viewContext.fetch(request).map(ChallengeEntityMapper.map(entity:))
        }
    }
}

private extension ChallengeEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ChallengeEntity> {
        NSFetchRequest<ChallengeEntity>(entityName: "ChallengeEntity")
    }
}
