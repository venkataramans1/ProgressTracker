import CoreData
import Foundation

struct CoreDataMigrator {
    private let modelName = "ProgressTrackerModel"

    func migrateIfNeeded(storeURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
        guard let destinationModel = managedObjectModel(versionName: "ProgressTrackerModel 2") else {
            return
        }
        if destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            return
        }
        guard let sourceModel = managedObjectModel(versionName: "ProgressTrackerModel 1"),
              sourceModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else {
            return
        }
        try performManualMigration(from: storeURL, sourceModel: sourceModel, destinationModel: destinationModel)
    }

    private func managedObjectModel(versionName: String) -> NSManagedObjectModel? {
        guard let modelURL = Bundle.main.url(forResource: versionName, withExtension: "mom", subdirectory: "\(modelName).momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: modelURL)
    }

    private func performManualMigration(from storeURL: URL, sourceModel: NSManagedObjectModel, destinationModel: NSManagedObjectModel) throws {
        let sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
        _ = try sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL)
        let sourceContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        sourceContext.persistentStoreCoordinator = sourceCoordinator

        let destinationCoordinator = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
        let tempURL = storeURL.deletingLastPathComponent().appendingPathComponent("\(UUID().uuidString).sqlite")
        _ = try destinationCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: tempURL)
        let destinationContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        destinationContext.persistentStoreCoordinator = destinationCoordinator

        try destinationContext.performAndWait {
            let challengeMap = try migrateChallenges(from: sourceContext, into: destinationContext)
            let objectiveMap = try migrateObjectives(from: sourceContext, into: destinationContext, challengeMap: challengeMap)
            try migrateMilestones(from: sourceContext, into: destinationContext, objectiveMap: objectiveMap)
            try migrateDailyEntries(from: sourceContext, into: destinationContext)
            if destinationContext.hasChanges {
                try destinationContext.save()
            }
        }

        try replaceStore(at: storeURL, with: tempURL)
    }

    private func migrateChallenges(from sourceContext: NSManagedObjectContext, into destinationContext: NSManagedObjectContext) throws -> [UUID: NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ChallengeEntity")
        let oldChallenges = try sourceContext.fetch(request)
        var map: [UUID: NSManagedObject] = [:]
        for oldChallenge in oldChallenges {
            guard let id = oldChallenge.value(forKey: "id") as? UUID else { continue }
            let newChallenge = NSEntityDescription.insertNewObject(forEntityName: "ChallengeEntity", into: destinationContext)
            newChallenge.setValue(id, forKey: "id")
            newChallenge.setValue(oldChallenge.value(forKey: "title"), forKey: "title")
            newChallenge.setValue(oldChallenge.value(forKey: "detail"), forKey: "detail")
            newChallenge.setValue(oldChallenge.value(forKey: "startDate"), forKey: "startDate")
            newChallenge.setValue(oldChallenge.value(forKey: "endDate"), forKey: "endDate")
            newChallenge.setValue(Challenge.Status.active.rawValue, forKey: "status")
            newChallenge.setValue(nil, forKey: "emoji")
            map[id] = newChallenge
        }
        return map
    }

    private func migrateObjectives(from sourceContext: NSManagedObjectContext, into destinationContext: NSManagedObjectContext, challengeMap: [UUID: NSManagedObject]) throws -> [UUID: NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "ObjectiveEntity")
        let oldObjectives = try sourceContext.fetch(request)
        var map: [UUID: NSManagedObject] = [:]
        for oldObjective in oldObjectives {
            guard let id = oldObjective.value(forKey: "id") as? UUID else { continue }
            let newObjective = NSEntityDescription.insertNewObject(forEntityName: "ObjectiveEntity", into: destinationContext)
            newObjective.setValue(id, forKey: "id")
            newObjective.setValue(oldObjective.value(forKey: "title"), forKey: "title")
            newObjective.setValue(oldObjective.value(forKey: "unit"), forKey: "unit")
            newObjective.setValue(oldObjective.value(forKey: "targetValue"), forKey: "targetValue")
            newObjective.setValue(oldObjective.value(forKey: "currentValue"), forKey: "currentValue")
            if let challenge = oldObjective.value(forKey: "challenge") as? NSManagedObject,
               let challengeId = challenge.value(forKey: "id") as? UUID,
               let newChallenge = challengeMap[challengeId] {
                newObjective.setValue(newChallenge, forKey: "challenge")
            }
            map[id] = newObjective
        }
        return map
    }

    private func migrateMilestones(from sourceContext: NSManagedObjectContext, into destinationContext: NSManagedObjectContext, objectiveMap: [UUID: NSManagedObject]) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MilestoneEntity")
        let oldMilestones = try sourceContext.fetch(request)
        for oldMilestone in oldMilestones {
            guard let id = oldMilestone.value(forKey: "id") as? UUID else { continue }
            let newMilestone = NSEntityDescription.insertNewObject(forEntityName: "MilestoneEntity", into: destinationContext)
            newMilestone.setValue(id, forKey: "id")
            newMilestone.setValue(oldMilestone.value(forKey: "title"), forKey: "title")
            newMilestone.setValue(oldMilestone.value(forKey: "targetDate"), forKey: "targetDate")
            newMilestone.setValue(oldMilestone.value(forKey: "isCompleted"), forKey: "isCompleted")
            if let objective = oldMilestone.value(forKey: "objective") as? NSManagedObject,
               let objectiveId = objective.value(forKey: "id") as? UUID,
               let newObjective = objectiveMap[objectiveId] {
                newMilestone.setValue(newObjective, forKey: "objective")
            }
        }
    }

    private func migrateDailyEntries(from sourceContext: NSManagedObjectContext, into destinationContext: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyEntryEntity")
        let oldEntries = try sourceContext.fetch(request)
        for oldEntry in oldEntries {
            guard let id = oldEntry.value(forKey: "id") as? UUID else { continue }
            let newEntry = NSEntityDescription.insertNewObject(forEntityName: "DailyEntryEntity", into: destinationContext)
            newEntry.setValue(id, forKey: "id")
            newEntry.setValue(oldEntry.value(forKey: "date"), forKey: "date")
            newEntry.setValue(oldEntry.value(forKey: "mood"), forKey: "mood")
            newEntry.setValue(nil, forKey: "editedAt")
            let notes = oldEntry.value(forKey: "notes") as? String
            let isCompleted = (oldEntry.value(forKey: "isCompleted") as? Bool) ?? false
            let metrics = oldEntry.value(forKey: "metrics") as? [String: Double] ?? [:]
            var detailObjects: [NSManagedObject] = []
            if metrics.isEmpty {
                let detail = NSEntityDescription.insertNewObject(forEntityName: "ChallengeDetailEntity", into: destinationContext)
                detail.setValue(UUID(), forKey: "id")
                detail.setValue(UUID(), forKey: "challengeId")
                detail.setValue(isCompleted, forKey: "isCompleted")
                detail.setValue(notes, forKey: "notes")
                detail.setValue([], forKey: "tags")
                detail.setValue([], forKey: "photoURLs")
                detail.setValue(newEntry, forKey: "dailyEntry")
                detailObjects.append(detail)
            } else {
                for (index, metric) in metrics.enumerated() {
                    let detail = NSEntityDescription.insertNewObject(forEntityName: "ChallengeDetailEntity", into: destinationContext)
                    detail.setValue(UUID(), forKey: "id")
                    detail.setValue(UUID(), forKey: "challengeId")
                    detail.setValue(isCompleted, forKey: "isCompleted")
                    detail.setValue(index == 0 ? notes : nil, forKey: "notes")
                    let tag = LegacyMetricTag.encoded(name: metric.key, value: metric.value)
                    detail.setValue([tag], forKey: "tags")
                    detail.setValue([], forKey: "photoURLs")
                    detail.setValue(newEntry, forKey: "dailyEntry")
                    detailObjects.append(detail)
                }
            }
            newEntry.setValue(NSSet(array: detailObjects), forKey: "challengeDetails")
        }
    }

    private func replaceStore(at originalURL: URL, with newURL: URL) throws {
        let fileManager = FileManager.default
        let shm = URL(fileURLWithPath: originalURL.path + "-shm")
        let wal = URL(fileURLWithPath: originalURL.path + "-wal")
        let newShm = URL(fileURLWithPath: newURL.path + "-shm")
        let newWal = URL(fileURLWithPath: newURL.path + "-wal")
        [originalURL, shm, wal].forEach { url in
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
        try fileManager.moveItem(at: newURL, to: originalURL)
        if fileManager.fileExists(atPath: newShm.path) {
            try fileManager.moveItem(at: newShm, to: shm)
        }
        if fileManager.fileExists(atPath: newWal.path) {
            try fileManager.moveItem(at: newWal, to: wal)
        }
    }
}
