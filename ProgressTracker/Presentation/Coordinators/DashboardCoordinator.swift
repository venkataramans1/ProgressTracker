import Foundation

final class DashboardCoordinator: Coordinator {
    enum Destination: Hashable {
        case challengeDetail(Challenge)
    }

    @Published var path: [Destination] = []
}
