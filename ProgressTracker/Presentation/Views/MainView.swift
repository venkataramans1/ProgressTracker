import SwiftUI

struct MainView: View {
    enum Tab: Hashable {
        case dashboard
        case insights
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .insights: return "Insights"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "speedometer"
            case .insights: return "chart.bar"
            case .settings: return "gearshape"
            }
        }
    }

    @ObservedObject var container: DependencyContainer
    @State private var selectedTab: Tab = .dashboard
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var insightsViewModel: InsightsViewModel
    @StateObject private var challengesCoordinator = ChallengesCoordinator()
    @State private var showingChallengeManager = false

    init(container: DependencyContainer) {
        self.container = container
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(
            getActiveChallengesUseCase: container.getActiveChallengesUseCase,
            dailyEntryRepository: container.dailyEntryRepository,
            saveDailyEntryUseCase: container.saveDailyEntryUseCase
        ))
        _insightsViewModel = StateObject(wrappedValue: InsightsViewModel(
            generateInsightsUseCase: container.generateInsightsUseCase,
            getChallengesUseCase: container.getChallengesUseCase
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardTab(viewModel: dashboardViewModel) {
                    showingChallengeManager = true
                }
            }
            .tabItem { Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon) }
            .tag(Tab.dashboard)

            NavigationStack {
                InsightsView(viewModel: insightsViewModel)
            }
            .tabItem { Label(Tab.insights.title, systemImage: Tab.insights.icon) }
            .tag(Tab.insights)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(Tab.settings.title, systemImage: Tab.settings.icon) }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showingChallengeManager) {
            ChallengesCoordinatorView(coordinator: challengesCoordinator)
                .environmentObject(container)
        }
    }
}
