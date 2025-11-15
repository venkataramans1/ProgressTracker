import Foundation

final class InsightsCoordinator: Coordinator {
    enum Destination: Hashable {}

    @Published var path: [Destination] = []
}
