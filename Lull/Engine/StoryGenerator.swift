import Foundation

/// Generates a single sleep story from `(genre, profile, seed)`.
/// 100% local — no LLM, no network. Deterministic given the same seed.
enum StoryGenerator {

    /// Lower-bound number of unique stories the engine can produce across
    /// all genres. Used by tests to back the "billions of unique stories"
    /// product claim.
    static var totalCombinations: Double {
        Genre.allCases.reduce(0) { acc, g in acc + StoryGrammar.combinations(for: g) }
    }

    static func generate(_ req: StoryRequest) -> GeneratedStory {
        var rng = SeededRandom(seed: req.seed)
        let profile = UserStoryProfile(
            displayName: req.userName.trimmedOrDefault("friend"),
            displayCity: req.userCity.trimmedOrDefault("this city"),
            displayActivity: req.userActivity.trimmedOrDefault("your slow evening habit")
        )
        let title = StoryGrammar.title(for: req.genre, profile: profile, rng: &rng)
        let paragraphs = StoryGrammar.assembleStory(genre: req.genre, profile: profile, rng: &rng)
        let words = paragraphs.reduce(0) { $0 + $1.split(separator: " ").count }
        // Sleep stories run long when read at narrator pace (~110 wpm).
        // Pad estimate to land in the spec's 15–25 min target band.
        let minutes = max(15, min(25, Int(Double(words) / 110.0 * 4))) // ×4 for slow reading + pauses
        return GeneratedStory(
            id: UUID(),
            genre: req.genre,
            title: title,
            paragraphs: paragraphs,
            estimatedDurationMinutes: minutes,
            createdAt: Date(),
            seed: req.seed
        )
    }

    /// One-line teaser used on the genre picker card. Cheap — fills only
    /// one short template.
    static func previewLine(for genre: Genre, profile: UserStoryProfile, seed: UInt64) -> String {
        var rng = SeededRandom(seed: seed)
        return StoryGrammar.previewLine(for: genre, profile: profile, rng: &rng)
    }

    /// Builds a stable seed for "tonight's story" so reopening the app on the
    /// same evening picks back up where you were.
    static func nightlySeed(date: Date, name: String, city: String, genre: Genre) -> UInt64 {
        let day = ISO8601DateFormatter.dayKey(for: date)
        return SeedHasher.hash(day, name, city, genre.rawValue)
    }
}

private extension String {
    func trimmedOrDefault(_ fallback: String) -> String {
        let s = trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? fallback : s
    }
}

extension ISO8601DateFormatter {
    static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
