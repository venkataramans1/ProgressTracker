import Foundation

/// Represents the mood selection associated with a daily log entry.
enum Mood: String, CaseIterable, Identifiable, Codable {
    case excellent
    case good
    case average
    case low
    case bad

    var id: String { rawValue }

    /// A human readable label used in the UI.
    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .average: return "Average"
        case .low: return "Low"
        case .bad: return "Bad"
        }
    }

    /// A system image name used alongside the label.
    var systemImageName: String {
        switch self {
        case .excellent: return "sun.max.fill"
        case .good: return "sunrise.fill"
        case .average: return "cloud.fill"
        case .low: return "cloud.drizzle.fill"
        case .bad: return "cloud.bolt.rain.fill"
        }
    }
}
