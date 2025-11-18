import Foundation

/// Simple view model to expose challenge details in read-only form.
@MainActor
final class ChallengeDetailViewModel: ObservableObject {
    @Published var challenge: Challenge

    init(challenge: Challenge) {
        self.challenge = challenge
    }
}
