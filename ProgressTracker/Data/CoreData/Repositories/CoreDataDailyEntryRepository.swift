import CoreData
import Foundation

final class CoreDataDailyEntryRepository: DailyEntryRepository {
    private let stack: CoreDataStack
    private let photoStorage: PhotoStoring

    init(stack: CoreDataStack = .shared, photoStorage: PhotoStoring = DefaultPhotoStorage()) {
        self.stack = stack
        self.photoStorage = photoStorage
    }

    func fetchEntries(startingFrom startDate: Date, to endDate: Date) async throws -> [DailyEntry] {
        let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntryEntity.date, ascending: true)]
        request.relationshipKeyPathsForPrefetching = ["challengeDetails"]
        return try await stack.container.viewContext.perform {
            try self.stack.container.viewContext.fetch(request).map(DailyEntryEntityMapper.map(entity:))
        }
    }

    func fetchEntry(for date: Date) async throws -> DailyEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        request.relationshipKeyPathsForPrefetching = ["challengeDetails"]
        return try await stack.container.viewContext.perform {
            try self.stack.container.viewContext.fetch(request).first.map(DailyEntryEntityMapper.map(entity:))
        }
    }

    func save(_ entry: DailyEntry) async throws {
        let context = stack.backgroundContext()
        try await context.perform {
            let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            request.fetchLimit = 1
            let entity = try context.fetch(request).first ?? DailyEntryEntity(context: context)
            var normalizedEntry = entry
            normalizedEntry.challengeDetails = try entry.challengeDetails.map { detail in
                var updatedDetail = detail
                updatedDetail.photoURLs = try detail.photoURLs.map { try self.photoStorage.persistIfNeeded(url: $0) }
                return updatedDetail
            }
            normalizedEntry.editedAt = entry.editedAt ?? Date()
            DailyEntryEntityMapper.update(entity: entity, from: normalizedEntry, in: context)
            try context.save()
        }
    }

    func delete(_ entry: DailyEntry) async throws {
        let context = stack.backgroundContext()
        try await context.perform {
            let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            request.fetchLimit = 1
            guard let entity = try context.fetch(request).first else {
                throw CoreDataRepositoryError.entityNotFound
            }
            let details = entity.challengeDetails as? Set<ChallengeDetailEntity> ?? []
            details.forEach { detail in
                let storedPhotoStrings = detail.photoURLs as? [String] ?? []
                storedPhotoStrings.compactMap { URL(string: $0) ?? URL(fileURLWithPath: $0) }.forEach { url in
                    try? self.photoStorage.remove(url: url)
                }
            }
            context.delete(entity)
            try context.save()
        }
    }

    func checkDuplicateEntry(for date: Date) async throws -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }
        let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        let count = try await stack.container.viewContext.perform {
            try self.stack.container.viewContext.count(for: request)
        }
        return count > 0
    }
}

private extension DailyEntryEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DailyEntryEntity> {
        NSFetchRequest<DailyEntryEntity>(entityName: "DailyEntryEntity")
    }
}
