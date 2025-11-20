import Foundation

/// View model powering the multi-step new challenge creation experience.
@MainActor
final class NewChallengeViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var detail: String = ""
    @Published var startDate: Date = Date()
    @Published var includeEndDate: Bool = false
    @Published var endDate: Date
    @Published var emoji: String = "🎯"
    @Published var trackingStyle: Challenge.TrackingStyle = .simpleCheck
    @Published var dailyTargetMinutesString: String = ""
    @Published private(set) var suggestedEmojis: [String] = []
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var savedChallenge: Challenge?

    private let saveChallengeUseCase: SaveChallengeUseCase
    private let calendar: Calendar

    init(
        saveChallengeUseCase: SaveChallengeUseCase,
        calendar: Calendar = .current,
        initialDate: Date = Date()
    ) {
        self.saveChallengeUseCase = saveChallengeUseCase
        self.calendar = calendar
        self.startDate = initialDate
        self.endDate = calendar.date(byAdding: .day, value: 30, to: initialDate) ?? initialDate
        generateEmojiSuggestions()
    }

    var canSave: Bool {
        isOverviewValid && isDailyTargetValid
    }

    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Challenge" : trimmed
    }

    var displayEmoji: String? {
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var detailSummary: String? {
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func save() async {
        guard canSave, let challenge = makeChallenge() else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await saveChallengeUseCase.execute(challenge)
            savedChallenge = challenge
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func dismissError() {
        errorMessage = nil
    }

    func generateEmojiSuggestions() {
        let normalized = title.lowercased()
        var matches: [String] = []
        for (keyword, emojis) in emojiSuggestionMap {
            if normalized.contains(keyword) {
                matches.append(contentsOf: emojis)
            }
        }
        if matches.isEmpty {
            matches = defaultEmojiPool.shuffled().prefix(4).map { $0 }
        } else {
            matches = Array(matches.prefix(4))
        }
        suggestedEmojis = matches
        if emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji == "🎯" {
            emoji = suggestedEmojis.first ?? emoji
        }
    }

    func selectEmojiSuggestion(_ suggestion: String) {
        emoji = suggestion
    }

    private var isOverviewValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTitle = !trimmedTitle.isEmpty
        let validEndDate = !includeEndDate || endDate >= startDate
        return hasTitle && validEndDate
    }

    private var isDailyTargetValid: Bool {
        guard trackingStyle == .trackTime else { return true }
        let trimmed = dailyTargetMinutesString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return Int(trimmed) ?? -1 >= 0
    }

    var dailyTargetValidationMessage: String? {
        guard trackingStyle == .trackTime else { return nil }
        let trimmed = dailyTargetMinutesString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Int(trimmed), value >= 0 else {
            return "Enter a non-negative whole number."
        }
        return nil
    }

    var dailyTargetMinutes: Int? {
        guard trackingStyle == .trackTime else { return nil }
        let trimmed = dailyTargetMinutesString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = Int(trimmed), value >= 0 else { return nil }
        return value
    }

    private func makeChallenge() -> Challenge? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }

        return Challenge(
            title: trimmedTitle,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: includeEndDate ? endDate : nil,
            status: .active,
            emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : emoji,
            trackingStyle: trackingStyle,
            dailyTargetMinutes: dailyTargetMinutes
        )
    }
}

private extension NewChallengeViewModel {
    var emojiSuggestionMap: [String: [String]] {
        [
            "read": ["📚", "📖", "🤓"],
            "book": ["📘", "📗"],
            "write": ["✍️", "📝"],
            "journal": ["📔", "📝"],
            "meditate": ["🧘", "🌿"],
            "yoga": ["🧘", "🕉️"],
            "run": ["🏃", "🏃‍♀️", "🏃‍♂️"],
            "walk": ["🚶", "🚶‍♀️"],
            "gym": ["🏋️", "💪"],
            "lift": ["🏋️‍♂️", "🏋️‍♀️"],
            "code": ["💻", "👨‍💻", "👩‍💻"],
            "cook": ["🍳", "🥘"],
            "study": ["📚", "🧠"],
            "sleep": ["😴", "🌙"],
            "water": ["💧", "🚰"],
            "drink": ["💧", "🥤"],
            "music": ["🎵", "🎧"],
            "guitar": ["🎸"],
            "piano": ["🎹"],
            "art": ["🎨", "🖌️"],
            "draw": ["✏️", "🖍️"],
            "clean": ["🧹", "🧼"],
            "budget": ["💰", "📊"]
        ]
    }

    var defaultEmojiPool: [String] {
        ["🎯", "💪", "🌟", "🚀", "🔥", "📈", "🌱", "☀️", "🧠", "🎧", "🏅", "🏃", "🧘", "📚", "🛠️"]
    }
}
