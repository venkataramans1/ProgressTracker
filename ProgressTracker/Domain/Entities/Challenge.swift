import Foundation

struct Challenge: Identifiable, Codable, Equatable, Hashable {
    enum Status: String, Codable, CaseIterable {
        case active
        case archived
        case deleted
    }

    let id: UUID
    var title: String
    var detail: String
    var startDate: Date
    var endDate: Date?
    var objectives: [Objective]
    var status: Status
    var emoji: String?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        startDate: Date,
        endDate: Date? = nil,
        objectives: [Objective] = [],
        status: Status = .active,
        emoji: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.startDate = startDate
        self.endDate = endDate
        self.objectives = objectives
        self.status = status
        self.emoji = emoji
    }

    var isActive: Bool {
        guard status == .active else { return false }
        let now = Date()
        if let end = endDate {
            return now >= startDate && now <= end
        }
        return now >= startDate
    }

    var progress: Double {
        guard !objectives.isEmpty else { return 0 }
        let total = objectives.reduce(0) { $0 + $1.progress }
        return total / Double(objectives.count)
    }
}
