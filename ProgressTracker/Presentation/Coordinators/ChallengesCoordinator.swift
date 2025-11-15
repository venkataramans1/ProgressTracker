import Foundation

final class ChallengesCoordinator: Coordinator {
    enum Destination: Hashable {
        case challengeDetail(Challenge)
    }

    @Published var path: [Destination] = []
}
