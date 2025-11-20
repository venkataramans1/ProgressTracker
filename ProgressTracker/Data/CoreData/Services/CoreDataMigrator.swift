import CoreData
import Foundation

/// Lightweight migrator that simply resets incompatible stores since the app is not in production.
struct CoreDataMigrator {
    
    func requiresMigration(at storeURL: URL, targetModel: NSManagedObjectModel) -> Bool {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return false }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL
            )
            return !targetModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            // If we can't read metadata, assume it's corrupt or incompatible
            print("⚠️ Failed to read store metadata: \(error)")
            return true
        }
    }
    
    func forceResetStore(at url: URL) {
        guard url.path != "/dev/null" else { return }
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            
            let shm = URL(fileURLWithPath: url.path + "-shm")
            if fileManager.fileExists(atPath: shm.path) {
                try fileManager.removeItem(at: shm)
            }
            
            let wal = URL(fileURLWithPath: url.path + "-wal")
            if fileManager.fileExists(atPath: wal.path) {
                try fileManager.removeItem(at: wal)
            }
            print("✅ Successfully reset store at \(url)")
        } catch {
            print("❌ Failed to reset store: \(error)")
        }
    }
}
