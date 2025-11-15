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
        let milestone1 = Milestone(title: "Complete first course", targetDate: calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        let milestone2 = Milestone(title: "Submit practice project", targetDate: calendar.date(byAdding: .day, value: 21, to: Date()) ?? Date())
        let milestone3 = Milestone(title: "Pass certification exam", targetDate: calendar.date(byAdding: .day, value: 45, to: Date()) ?? Date())

        let objective1 = Objective(title: "Study hours", targetValue: 100, currentValue: 35, unit: "hrs", milestones: [milestone1])
        let objective2 = Objective(title: "Practice projects", targetValue: 3, currentValue: 1, unit: "projects", milestones: [milestone2])
        let objective3 = Objective(title: "Mock exams", targetValue: 5, currentValue: 2, unit: "exams", milestones: [milestone3])

        let challenge = Challenge(
            title: "iOS Development Certification",
            detail: "Prepare for the certification exam in 8 weeks.",
            startDate: calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            endDate: calendar.date(byAdding: .day, value: 50, to: Date()),
            objectives: [objective1, objective2, objective3]
        )

        try await challengeRepository.save(challenge)
    }

    private func seedEntries() async throws {
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let metrics: [String: Double] = [
                "Focus (hrs)": Double.random(in: 1...4),
                "Exercise": Double.random(in: 0...1)
            ]
            let entry = DailyEntry(
                date: date,
                notes: "Completed study session and practice tasks.",
                mood: Mood.allCases.randomElement() ?? .average,
                metrics: metrics,
                isCompleted: Bool.random()
            )
            try await entryRepository.save(entry)
        }
    }
}
