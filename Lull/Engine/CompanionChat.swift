import Foundation

/// Public façade for the chat engine. Stateless — the caller owns history.
enum CompanionChat {

    /// Lower bound on the number of distinct replies the grammar can produce.
    /// Backs the "billions of unique replies" product claim and the
    /// `CompanionChatTests.testReplyCombinatoricSpaceExceedsOneBillion` test.
    static var totalReplyCombinations: Double {
        ChatGrammar.totalCombinations()
    }

    /// Generate a contextual reply.
    /// - Parameters:
    ///   - message: the user's latest message
    ///   - history: prior messages (oldest first). Currently used only for
    ///     analysis context; future versions can reference past topics.
    ///   - profile: name/city/activity for slot-fill personalization
    ///   - extraEntropy: additional bytes mixed into the seed so two identical
    ///     messages in the same conversation don't return the same reply.
    static func reply(to message: String,
                      history: [ChatMessage] = [],
                      profile: UserStoryProfile,
                      extraEntropy: String = "") -> String {

        let analysis = MessageAnalyzer.analyze(message, history: history)

        // Seed: message text + last companion msg + entropy. Stable per turn,
        // varies turn-over-turn even when user sends the same word twice.
        let lastCompanion = history.last(where: { $0.role == .companion })?.body ?? ""
        let seed = SeedHasher.hash(
            message,
            lastCompanion,
            profile.displayName,
            extraEntropy
        )
        var rng = SeededRandom(seed: seed)

        return ChatGrammar.compose(for: analysis, profile: profile, rng: &rng)
    }

    /// Convenience for the very first opener when the user hasn't typed yet.
    static func initialGreeting(profile: UserStoryProfile, seed: UInt64) -> String {
        let analysis = MessageAnalysis(
            intent: .greet,
            topic: nil,
            bodyState: nil,
            polarity: .neutral,
            isShort: true,
            normalized: ""
        )
        var rng = SeededRandom(seed: seed)
        return ChatGrammar.compose(for: analysis, profile: profile, rng: &rng)
    }
}
