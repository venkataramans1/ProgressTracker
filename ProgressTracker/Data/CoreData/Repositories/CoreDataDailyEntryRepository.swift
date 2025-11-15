import CoreData
import Foundation

/// Implements the `DailyEntryRepository` backed by Core Data.
final class CoreDataDailyEntryRepository: DailyEntryRepository {
    private let stack: CoreDataStack

    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }

    func fetchEntries(startingFrom startDate: Date, to endDate: Date) async throws -> [DailyEntry] {
        let request: NSFetchRequest<DailyEntryEntity> = DailyEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntryEntity.date, ascending: true)]
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
            DailyEntryEntityMapper.update(entity: entity, from: entry)
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
            context.delete(entity)
            try context.save()
        }
    }
}

private extension DailyEntryEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DailyEntryEntity> {
        NSFetchRequest<DailyEntryEntity>(entityName: "DailyEntryEntity")
    }
}
