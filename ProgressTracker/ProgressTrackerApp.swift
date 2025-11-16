import SwiftUI
import UIKit
import UserNotifications

@main
struct ProgressTrackerApp: App {
    @StateObject private var dependencyContainer = DependencyContainer()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        configureNotifications()
    }

    var body: some Scene {
        WindowGroup {
            MainView(container: dependencyContainer)
                .environmentObject(dependencyContainer)
        }
    }

    private func configureNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            if granted {
                LocalNotificationService.shared.scheduleDailyReminder()
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}
