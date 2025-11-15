import Foundation

final class DailyLogCoordinator: Coordinator {
    enum Destination: Hashable {
        case entryDetail(DailyEntry)
    }

    @Published var path: [Destination] = []
}
