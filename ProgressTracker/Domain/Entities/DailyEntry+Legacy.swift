import Foundation

enum LegacyMetricTag {
    static let prefix = "metric"

    static func encoded(name: String, value: Double) -> String {
        "\(prefix)|\(name)|\(value)"
    }

    static func decode(tag: String) -> (String, Double)? {
        guard tag.hasPrefix("\(prefix)|") else { return nil }
        let components = tag.split(separator: "|", omittingEmptySubsequences: false)
        guard components.count == 3, let value = Double(components[2]) else { return nil }
        return (String(components[1]), value)
    }
}

extension DailyEntry {
    init(
        id: UUID = UUID(),
        date: Date,
        notes: String = "",
        mood: Mood,
        metrics: [String: Double] = [:],
        isCompleted: Bool = false
    ) {
        let details: [ChallengeDetail]
        if metrics.isEmpty {
            let detail = ChallengeDetail(
                challengeId: UUID(),
                isCompleted: isCompleted,
                notes: notes,
                photoURLs: [],
                tags: []
            )
            details = [detail]
        } else {
            details = metrics.enumerated().map { index, metric in
                let tag = LegacyMetricTag.encoded(name: metric.key, value: metric.value)
                return ChallengeDetail(
                    challengeId: UUID(),
                    isCompleted: isCompleted,
                    notes: index == 0 ? notes : nil,
                    photoURLs: [],
                    tags: [tag]
                )
            }
        }
        self.init(id: id, date: date, mood: mood, challengeDetails: details)
    }

    var notes: String {
        challengeDetails.first?.notes ?? ""
    }

    var metrics: [String: Double] {
        var result: [String: Double] = [:]
        for detail in challengeDetails {
            guard let tag = detail.tags.first, let decoded = LegacyMetricTag.decode(tag: tag) else { continue }
            result[decoded.0] = decoded.1
        }
        return result
    }

    var isCompleted: Bool {
        challengeDetails.allSatisfy { $0.isCompleted }
    }

    var resolvedMood: Mood {
        mood ?? .average
    }
}
