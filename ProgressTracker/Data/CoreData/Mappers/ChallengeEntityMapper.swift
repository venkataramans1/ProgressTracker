import CoreData
import Foundation

struct ChallengeEntityMapper {
    static func map(entity: ChallengeManagedObject) -> Challenge {
        let status = Challenge.Status(rawValue: entity.status) ?? .active
        let trackingStyle = Challenge.TrackingStyle(rawValue: entity.trackingStyle) ?? .simpleCheck
        let dailyTarget = entity.dailyTargetMinutes?.intValue
        return Challenge(
            id: entity.id,
            title: entity.title,
            detail: entity.detail ?? "",
            startDate: entity.startDate,
            endDate: entity.endDate,
            status: status,
            emoji: entity.emoji,
            trackingStyle: trackingStyle,
            dailyTargetMinutes: dailyTarget
        )
    }

    @discardableResult
    static func update(entity: ChallengeManagedObject, from challenge: Challenge) -> ChallengeManagedObject {
        entity.id = challenge.id
        entity.title = challenge.title
        entity.detail = challenge.detail
        entity.startDate = challenge.startDate
        entity.endDate = challenge.endDate
        entity.status = challenge.status.rawValue
        entity.emoji = challenge.emoji
        entity.trackingStyle = challenge.trackingStyle.rawValue
        entity.dailyTargetMinutes = challenge.dailyTargetMinutes.map { NSNumber(value: $0) }
        return entity
    }
}
