import CoreData
import Foundation

@objc(ChallengeManagedObject)
final class ChallengeManagedObject: NSManagedObject {
    @objc var id: UUID {
        get { readAttribute("id") ?? UUID() }
        set { writeAttribute(newValue, key: "id") }
    }

    @objc var title: String {
        get { readAttribute("title") ?? "" }
        set { writeAttribute(newValue, key: "title") }
    }

    @objc var detail: String? {
        get { readAttribute("detail") }
        set { writeAttribute(newValue, key: "detail") }
    }

    @NSManaged var startDate: Date
    @NSManaged var endDate: Date?

    @objc var status: String {
        get { readAttribute("status") ?? Challenge.Status.active.rawValue }
        set { writeAttribute(newValue, key: "status") }
    }

    @objc var emoji: String? {
        get { readAttribute("emoji") }
        set { writeAttribute(newValue, key: "emoji") }
    }

    @objc var trackingStyle: String {
        get { readAttribute("trackingStyle") ?? Challenge.TrackingStyle.simpleCheck.rawValue }
        set { writeAttribute(newValue, key: "trackingStyle") }
    }

    @objc var dailyTargetMinutes: NSNumber? {
        get { readAttribute("dailyTargetMinutes") }
        set { writeAttribute(newValue, key: "dailyTargetMinutes") }
    }

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
