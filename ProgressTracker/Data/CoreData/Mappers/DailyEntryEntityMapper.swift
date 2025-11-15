import CoreData
import Foundation

/// Maps Core Data `DailyEntryEntity` objects into domain `DailyEntry` models and vice versa.
struct DailyEntryEntityMapper {
    static func map(entity: DailyEntryEntity) -> DailyEntry {
        let metrics = entity.metrics as? [String: Double] ?? [:]
        let moodValue = Mood(rawValue: entity.mood) ?? .average
        return DailyEntry(
            id: entity.id,
            date: entity.date,
            notes: entity.notes ?? "",
            mood: moodValue,
            metrics: metrics,
            isCompleted: entity.isCompleted
        )
    }

    static func update(entity: DailyEntryEntity, from entry: DailyEntry) {
        entity.id = entry.id
        entity.date = entry.date
        entity.notes = entry.notes
        entity.mood = entry.mood.rawValue
        entity.metrics = entry.metrics as NSDictionary
        entity.isCompleted = entry.isCompleted
    }
}
