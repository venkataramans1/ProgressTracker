import Foundation

/// Base protocol for coordinators to allow for navigation orchestration.
protocol Coordinator: ObservableObject {
    associatedtype Destination: Hashable
    var path: [Destination] { get set }
    func push(_ destination: Destination)
    func pop()
    func reset()
}

extension Coordinator {
    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        _ = path.popLast()
    }

    func reset() {
        path.removeAll()
    }
}
