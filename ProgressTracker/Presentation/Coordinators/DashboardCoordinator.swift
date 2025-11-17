import Foundation

final class DashboardCoordinator: Coordinator {
    enum Destination: Hashable {
        case challengeDetail(Challenge)
        case newChallenge
    }

    @Published var path: [Destination] = []
}
