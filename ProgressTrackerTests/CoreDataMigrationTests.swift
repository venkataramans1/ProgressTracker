import CoreData
import XCTest
@testable import ProgressTracker

final class CoreDataMigrationTests: XCTestCase {
    func testMigrationFromEmptyStoreDoesNotCrash() throws {
        let storeURL = try makeTemporaryStoreURL(name: "Empty")
        try buildLegacyStore(at: storeURL, entryCount: 0)
        XCTAssertNoThrow(try CoreDataMigrator().migrateIfNeeded(storeURL: storeURL))
        let context = try loadContextForCurrentModel(at: storeURL)
        let entries = try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "DailyEntryEntity"))
        XCTAssertEqual(entries, 0)
    }

    func testMigrationFromSingleEntry() throws {
        let storeURL = try makeTemporaryStoreURL(name: "Single")
        try buildLegacyStore(at: storeURL, entryCount: 1)
        try CoreDataMigrator().migrateIfNeeded(storeURL: storeURL)
        let context = try loadContextForCurrentModel(at: storeURL)
        let entryRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyEntryEntity")
        let entries = try context.fetch(entryRequest)
        XCTAssertEqual(entries.count, 1)
        let entry = entries[0]
        let details = entry.value(forKey: "challengeDetails") as? Set<NSManagedObject>
        XCTAssertEqual(details?.count, 2)
        let challengeRequest = NSFetchRequest<NSManagedObject>(entityName: "ChallengeEntity")
        let challenges = try context.fetch(challengeRequest)
        XCTAssertEqual(challenges.first?.value(forKey: "status") as? String, Challenge.Status.active.rawValue)
    }

    func testMigrationFromLargeStore() throws {
        let storeURL = try makeTemporaryStoreURL(name: "Large")
        try buildLegacyStore(at: storeURL, entryCount: 150)
        try CoreDataMigrator().migrateIfNeeded(storeURL: storeURL)
        let context = try loadContextForCurrentModel(at: storeURL)
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyEntryEntity")
        let entries = try context.fetch(request)
        XCTAssertEqual(entries.count, 150)
        let totalDetails = entries.compactMap { $0.value(forKey: "challengeDetails") as? Set<NSManagedObject> }
            .reduce(0) { $0 + $1.count }
        XCTAssertEqual(totalDetails, 150 * 2)
    }

    private func makeTemporaryStoreURL(name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(name).sqlite")
    }

    private func buildLegacyStore(at storeURL: URL, entryCount: Int) throws {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "ProgressTrackerModel 1", withExtension: "mom", subdirectory: "ProgressTrackerModel.momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            XCTFail("Unable to load legacy model")
            return
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        let challenge = NSEntityDescription.insertNewObject(forEntityName: "ChallengeEntity", into: context)
        challenge.setValue(UUID(), forKey: "id")
        challenge.setValue("Focus", forKey: "title")
        challenge.setValue("Test", forKey: "detail")
        challenge.setValue(Date(), forKey: "startDate")
        challenge.setValue(Date(), forKey: "endDate")

        context.performAndWait {
            for index in 0..<entryCount {
                let entry = NSEntityDescription.insertNewObject(forEntityName: "DailyEntryEntity", into: context)
                entry.setValue(UUID(), forKey: "id")
                entry.setValue(Date().addingTimeInterval(TimeInterval(86400 * index)), forKey: "date")
                entry.setValue("good", forKey: "mood")
                entry.setValue(true, forKey: "isCompleted")
                entry.setValue("Notes \(index)", forKey: "notes")
                entry.setValue(["Focus (hrs)": 1.0, "Exercise (mins)": 30.0], forKey: "metrics")
            }
            do {
                try context.save()
            } catch {
                XCTFail("Failed to save legacy context: \(error)")
            }
        }
    }

    private func loadContextForCurrentModel(at storeURL: URL) throws -> NSManagedObjectContext {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "ProgressTrackerModel 2", withExtension: "mom", subdirectory: "ProgressTrackerModel.momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw NSError(domain: "Tests", code: 0)
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }
}
