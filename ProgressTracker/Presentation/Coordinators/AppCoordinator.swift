import Combine
import Foundation
import SwiftUI

/// Enumeration that represents each tab in the application.
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case dailyLog
    case challenges
    case insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .dailyLog: return "Daily Log"
        case .challenges: return "Challenges"
        case .insights: return "Insights"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "speedometer"
        case .dailyLog: return "square.and.pencil"
        case .challenges: return "flag.2.crossed"
        case .insights: return "chart.bar"
        }
    }
}

/// Coordinates the top-level navigation and owns the dependency container.
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    let dependencyContainer = DependencyContainer()

    let dashboardCoordinator = DashboardCoordinator()
    let dailyLogCoordinator = DailyLogCoordinator()
    let challengesCoordinator = ChallengesCoordinator()
    let insightsCoordinator = InsightsCoordinator()
}

/// Hosts the tab navigation for the app.
struct CoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            DashboardCoordinatorView(coordinator: coordinator.dashboardCoordinator)
                .tabItem {
                    Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.systemImage)
                }
                .tag(AppTab.dashboard)

            DailyLogCoordinatorView(coordinator: coordinator.dailyLogCoordinator)
                .tabItem {
                    Label(AppTab.dailyLog.title, systemImage: AppTab.dailyLog.systemImage)
                }
                .tag(AppTab.dailyLog)

            ChallengesCoordinatorView(coordinator: coordinator.challengesCoordinator)
                .tabItem {
                    Label(AppTab.challenges.title, systemImage: AppTab.challenges.systemImage)
                }
                .tag(AppTab.challenges)

            InsightsCoordinatorView(coordinator: coordinator.insightsCoordinator)
                .tabItem {
                    Label(AppTab.insights.title, systemImage: AppTab.insights.systemImage)
                }
                .tag(AppTab.insights)
        }
    }
}
