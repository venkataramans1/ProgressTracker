import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer
    private let modelName = "ProgressTrackerModel"
    private let storeFilename = "ProgressTrackerModelV3.sqlite"

    private init(inMemory: Bool = false) {
        // 1. Load the specific model version (V3)
        guard let modelURL = Bundle.main.url(forResource: "ProgressTrackerModel 3", withExtension: "mom", subdirectory: "\(modelName).momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load ProgressTrackerModel 3")
        }

        // 2. Initialize container with the specific model
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        let defaultURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(storeFilename)
        let storeDescription = NSPersistentStoreDescription(url: defaultURL)
        
        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 3. Check for compatibility and reset if needed
            let migrator = CoreDataMigrator()
            if migrator.requiresMigration(at: defaultURL, targetModel: model) {
                print("⚠️ Store is incompatible. Resetting store at \(defaultURL)")
                migrator.forceResetStore(at: defaultURL)
            }
        }

        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]

        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Failed to load persistent store: \(error). Attempting final reset...")
                // Last ditch effort: nuke it and try again
                try? CoreDataMigrator().forceResetStore(at: defaultURL)
                do {
                    try self.container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: defaultURL, options: nil)
                } catch {
                    fatalError("Unrecoverable Core Data error: \(error)")
                }
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func backgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
