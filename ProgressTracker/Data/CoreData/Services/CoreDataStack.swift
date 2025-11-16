import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ProgressTrackerModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        if let storeURL = container.persistentStoreDescriptions.first?.url, storeURL.path != "/dev/null" {
            try? CoreDataMigrator().migrateIfNeeded(storeURL: storeURL)
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func backgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
