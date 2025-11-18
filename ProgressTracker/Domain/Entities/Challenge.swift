import Foundation

struct Challenge: Identifiable, Codable, Equatable, Hashable {
    enum Status: String, Codable, CaseIterable {
        case active
        case archived
        case deleted
    }

    enum TrackingStyle: String, Codable, CaseIterable, Identifiable {
        case simpleCheck
        case trackTime

        var id: String { rawValue }

        var title: String {
            switch self {
            case .simpleCheck: return "Simple check"
            case .trackTime: return "Track time"
            }
        }

        var helperText: String {
            switch self {
            case .simpleCheck:
                return "A quick daily done/not done. No minutes tracked."
            case .trackTime:
                return "Log minutes (+15, +30, etc.) and mark the day complete when you reach your goal."
            }
        }
    }

    let id: UUID
    var title: String
    var detail: String
    var startDate: Date
    var endDate: Date?
    var status: Status
    var emoji: String?
    var trackingStyle: TrackingStyle
    var dailyTargetMinutes: Int?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        startDate: Date,
        endDate: Date? = nil,
        status: Status = .active,
        emoji: String? = nil,
        trackingStyle: TrackingStyle = .simpleCheck,
        dailyTargetMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.emoji = emoji
        self.trackingStyle = trackingStyle
        self.dailyTargetMinutes = dailyTargetMinutes
    }

    var isActive: Bool {
        guard status == .active else { return false }
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }

    var requiresTimeLogging: Bool {
        trackingStyle == .trackTime
    }
}
