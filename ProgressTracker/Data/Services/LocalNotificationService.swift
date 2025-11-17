import Foundation
import UserNotifications

/// Manages scheduling of local notifications for daily reminders.
final class LocalNotificationService {
    static let shared = LocalNotificationService()

    private init() {}

    func scheduleDailyReminder(at hour: Int = 20) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily-progress-reminder"])

        var components = DateComponents()
        components.hour = hour

        let content = UNMutableNotificationContent()
        content.title = "Log your progress"
        content.body = "Remember to record today's achievements!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-progress-reminder", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    /// Schedules a lightweight nudge encouraging resilience habits.
    func scheduleResilienceNudge(message: String, after timeInterval: TimeInterval = 5) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["resilience-nudge"])

        let content = UNMutableNotificationContent()
        content.title = "Stay resilient"
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeInterval), repeats: false)
        let request = UNNotificationRequest(identifier: "resilience-nudge", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule resilience nudge: \(error.localizedDescription)")
            }
        }
    }
}
