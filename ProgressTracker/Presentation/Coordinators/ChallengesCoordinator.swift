import Foundation

final class ChallengesCoordinator: Coordinator {
    enum Destination: Hashable {
        case challengeDetail(Challenge)
        case newChallenge
    }

    @Published var path: [Destination] = []
}
