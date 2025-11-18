import CoreData
import Foundation

/// Lightweight migrator that simply resets incompatible stores since the app is not in production.
struct CoreDataMigrator {
    private let modelName = "ProgressTrackerModel"
    private let currentVersionName = "ProgressTrackerModel 3"

    func migrateIfNeeded(storeURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL
        )
        guard let destinationModel = managedObjectModel(versionName: currentVersionName) else { return }
        if destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            return
        }
        try removeStore(at: storeURL)
    }

    private func managedObjectModel(versionName: String) -> NSManagedObjectModel? {
        guard let modelURL = Bundle.main.url(forResource: versionName, withExtension: "mom", subdirectory: "\(modelName).momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: modelURL)
    }

    private func removeStore(at url: URL) throws {
        let fileManager = FileManager.default
        let shm = URL(fileURLWithPath: url.path + "-shm")
        let wal = URL(fileURLWithPath: url.path + "-wal")
        try? fileManager.removeItem(at: shm)
        try? fileManager.removeItem(at: wal)
        try fileManager.removeItem(at: url)
    }
}
