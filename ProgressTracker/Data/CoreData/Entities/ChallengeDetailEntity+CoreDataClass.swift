import CoreData
import Foundation

@objc(ChallengeDetailEntity)
final class ChallengeDetailEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var challengeId: UUID
    @NSManaged var isCompleted: Bool
    @objc var loggedMinutes: NSNumber? {
        get { readAttribute("loggedMinutes") }
        set { writeAttribute(newValue, key: "loggedMinutes") }
    }
    @objc var notes: String? {
        get { readAttribute("notes") }
        set { writeAttribute(newValue, key: "notes") }
    }
    @objc var photoURLs: NSArray? {
        get { readAttribute("photoURLs") }
        set { writeAttribute(newValue, key: "photoURLs") }
    }
    @objc var tags: NSArray? {
        get { readAttribute("tags") }
        set { writeAttribute(newValue, key: "tags") }
    }
    @NSManaged var dailyEntry: DailyEntryEntity

    private func readAttribute<T>(_ key: String) -> T? {
        guard entity.attributesByName[key] != nil else { return nil }
        willAccessValue(forKey: key)
        defer { didAccessValue(forKey: key) }
        return primitiveValue(forKey: key) as? T
    }

    private func writeAttribute(_ value: Any?, key: String) {
        guard entity.attributesByName[key] != nil else { return }
        willChangeValue(forKey: key)
        setPrimitiveValue(value, forKey: key)
        didChangeValue(forKey: key)
    }
}
