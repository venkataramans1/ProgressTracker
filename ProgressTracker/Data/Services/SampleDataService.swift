import Foundation

/// Seeds the database with sample data that can be used for previews and manual testing.
final class SampleDataService {
    private let challengeRepository: ChallengeRepository
    private let entryRepository: DailyEntryRepository
    private let calendar: Calendar

    init(
        challengeRepository: ChallengeRepository,
        entryRepository: DailyEntryRepository,
        calendar: Calendar = .current
    ) {
        self.challengeRepository = challengeRepository
        self.entryRepository = entryRepository
        self.calendar = calendar
    }

    /// Inserts sample data if the persistent store is empty.
    func populateIfNeeded() async {
        do {
            let challenges = try await challengeRepository.fetchAllChallenges()
            if challenges.isEmpty {
                try await seedChallenges()
            }
            let entries = try await entryRepository.fetchEntries(startingFrom: calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date(), to: Date())
            if entries.isEmpty {
                try await seedEntries()
            }
        } catch {
            print("Sample data population failed: \(error)")
        }
    }

    private func seedChallenges() async throws {
        let today = Date()
        let challenges = [
            Challenge(
                title: "Drink Water",
                detail: "Refill your bottle and drink 8 cups.",
                startDate: calendar.date(byAdding: .day, value: -5, to: today) ?? today,
                emoji: "💧",
                trackingStyle: .simpleCheck
            ),
            Challenge(
                title: "Focus Sprint",
                detail: "Spend at least 45 minutes on deep work.",
                startDate: calendar.date(byAdding: .day, value: -10, to: today) ?? today,
                emoji: "💻",
                trackingStyle: .trackTime,
                dailyTargetMinutes: 45
            ),
            Challenge(
                title: "Read a Book",
                detail: "Open a book daily—track 30 minute sessions.",
                startDate: calendar.date(byAdding: .day, value: -3, to: today) ?? today,
                emoji: "📚",
                trackingStyle: .trackTime,
                dailyTargetMinutes: 30
            )
        ]

        for challenge in challenges {
            try await challengeRepository.save(challenge)
        }
    }

    private func seedEntries() async throws {
        let challenges = try await challengeRepository.fetchAllChallenges()
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let mood = Mood.allCases.randomElement() ?? .average
            let details: [ChallengeDetail] = challenges.map { challenge in
                switch challenge.trackingStyle {
                case .simpleCheck:
                    let completed = Bool.random()
                    return ChallengeDetail(
                        challengeId: challenge.id,
                        isCompleted: completed,
                        notes: completed ? "Completed on time." : nil
                    )
                case .trackTime:
                    let minutes = Int.random(in: 0...75)
                    let target = challenge.dailyTargetMinutes ?? 0
                    let completed = target > 0 ? minutes >= target : Bool.random()
                    return ChallengeDetail(
                        challengeId: challenge.id,
                        isCompleted: completed,
                        loggedMinutes: minutes,
                        notes: completed ? "Felt productive." : nil
                    )
                }
            }
            let entry = DailyEntry(
                date: date,
                mood: mood,
                challengeDetails: details
            )
            try await entryRepository.save(entry)
        }
    }
}
