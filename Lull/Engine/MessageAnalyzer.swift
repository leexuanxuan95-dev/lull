import Foundation

/// What we infer from a user's chat message before composing a reply.
/// Intentionally crude — keyword + regex rules, no NLP framework. Tuned
/// for the only context this app cares about: a person trying to sleep.
struct MessageAnalysis: Equatable {
    let intent: ChatIntent
    let topic: ChatTopic?
    let bodyState: BodyState?
    let polarity: Polarity
    let isShort: Bool
    /// Original message lowercased, lightly normalized. Useful when the
    /// composer wants to echo a phrase back.
    let normalized: String
}

enum ChatIntent: String, Equatable {
    case greet
    case farewell
    case thanks
    case acknowledgement   // "ok", "yeah", "mhm"
    case anxious
    case cantSleep
    case overthinking
    case sad
    case lonely
    case worried           // pair with `topic` for specificity
    case scared
    case restless
    case grateful
    case requestStory
    case requestBreathing
    case requestQuiet
    case venting           // long, mixed signals
    case neutral
}

enum ChatTopic: String, Equatable {
    case work, money, family, partner, health, future, past, world
}

enum BodyState: String, Equatable {
    case hot, cold, restless, achey, tired, wired
}

enum Polarity: String, Equatable {
    case positive, negative, mixed, neutral
}

enum MessageAnalyzer {

    static func analyze(_ raw: String, history: [ChatMessage] = []) -> MessageAnalysis {
        let normalized = raw
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let isShort = normalized.split(separator: " ").count <= 2

        let topic = detectTopic(in: normalized)
        let body = detectBody(in: normalized)
        let polarity = detectPolarity(in: normalized)
        let intent = detectIntent(in: normalized,
                                  topic: topic,
                                  body: body,
                                  polarity: polarity,
                                  isShort: isShort)

        return MessageAnalysis(
            intent: intent,
            topic: topic,
            bodyState: body,
            polarity: polarity,
            isShort: isShort,
            normalized: normalized
        )
    }

    // MARK: - Intent

    private static func detectIntent(in s: String,
                                     topic: ChatTopic?,
                                     body: BodyState?,
                                     polarity: Polarity,
                                     isShort: Bool) -> ChatIntent {

        if s.isEmpty { return .neutral }

        // Order matters: most specific first.
        if matches(s, any: ["good night", "goodnight", "night night", "bye", "talk later"]) {
            return .farewell
        }
        if matches(s, any: ["thank you", "thanks", "thx", "appreciate"]) {
            return .thanks
        }
        if matches(s, any: ["hi", "hello", "hey", "hiya"]) && isShort {
            return .greet
        }
        if matches(s, any: ["ok", "okay", "yeah", "yes", "mhm", "mm-hm", "sure", "k"]) && isShort {
            return .acknowledgement
        }
        if matches(s, any: ["tell me a story", "story please", "read me a story", "i want a story", "give me a story"]) {
            return .requestStory
        }
        if matches(s, any: ["breath", "breathe", "breathing", "calm me", "ground me"]) {
            return .requestBreathing
        }
        if matches(s, any: ["just sit", "stay quiet", "no words", "shh", "don't talk", "just be here"]) {
            return .requestQuiet
        }
        if matches(s, any: ["scared", "afraid", "frightened", "nightmare", "bad dream"]) {
            return .scared
        }
        if matches(s, any: ["anxious", "anxiety", "panicking", "panic", "freaking out", "on edge"]) {
            return .anxious
        }
        if matches(s, any: ["can't sleep", "cant sleep", "wide awake", "can not sleep", "won't sleep", "no sleep"]) {
            return .cantSleep
        }
        if matches(s, any: ["overthinking", "spiraling", "spinning", "racing thoughts", "won't stop thinking", "can't stop thinking", "looping"]) {
            return .overthinking
        }
        if matches(s, any: ["sad", "depressed", "down", "low", "miserable", "heavy"]) {
            return .sad
        }
        if matches(s, any: ["lonely", "alone", "no one", "miss someone", "wish someone"]) {
            return .lonely
        }
        if matches(s, any: ["worried", "worry", "stressed", "stressing", "freaked"]) {
            return .worried
        }
        if matches(s, any: ["grateful", "thankful", "good day", "lucky", "happy"]) {
            return .grateful
        }
        if let _ = body, matches(s, any: ["restless", "tossing", "turning", "won't relax", "twitchy", "wired"]) {
            return .restless
        }
        // Long messages with negative polarity → venting
        if !isShort && s.count > 60 && (polarity == .negative || polarity == .mixed) {
            return .venting
        }
        // Topic without obvious emotion → likely worried about it
        if topic != nil && polarity == .negative {
            return .worried
        }
        return .neutral
    }

    // MARK: - Topic

    private static func detectTopic(in s: String) -> ChatTopic? {
        if matches(s, any: ["work", "job", "boss", "meeting", "deadline", "project", "interview", "office", "client"]) { return .work }
        if matches(s, any: ["money", "rent", "bills", "broke", "afford", "savings", "debt", "paycheck"]) { return .money }
        if matches(s, any: ["mom", "dad", "mum", "parent", "kids", "kid", "child", "sister", "brother", "family"]) { return .family }
        if matches(s, any: ["partner", "boyfriend", "girlfriend", "husband", "wife", "ex", "dating", "breakup", "relationship"]) { return .partner }
        if matches(s, any: ["health", "sick", "doctor", "pain", "hurts", "hurting", "diagnosis", "results"]) { return .health }
        if matches(s, any: ["tomorrow", "next week", "future", "afraid of what", "what if", "uncertain"]) { return .future }
        if matches(s, any: ["regret", "should have", "shouldn't have", "wish i had", "remember when", "years ago"]) { return .past }
        if matches(s, any: ["news", "world", "war", "election", "climate", "politics"]) { return .world }
        return nil
    }

    // MARK: - Body state

    private static func detectBody(in s: String) -> BodyState? {
        if matches(s, any: ["hot", "sweaty", "warm", "overheated"]) { return .hot }
        if matches(s, any: ["cold", "freezing", "shivering", "chilly"]) { return .cold }
        if matches(s, any: ["restless", "tossing", "turning", "twitchy"]) { return .restless }
        if matches(s, any: ["sore", "achey", "achy", "back hurts", "neck"]) { return .achey }
        if matches(s, any: ["exhausted", "tired", "drained", "wiped"]) { return .tired }
        if matches(s, any: ["wired", "buzzing", "amped", "can't settle"]) { return .wired }
        return nil
    }

    // MARK: - Polarity

    private static let negWords: Set<String> = [
        "not", "no", "never", "bad", "awful", "terrible", "hate", "horrible",
        "tired", "sad", "scared", "anxious", "stressed", "worried", "lonely",
        "depressed", "afraid", "miserable", "broken", "wrong", "hurt"
    ]
    private static let posWords: Set<String> = [
        "good", "great", "happy", "grateful", "lucky", "calm", "peaceful",
        "okay", "fine", "better", "soft", "warm", "kind"
    ]

    private static func detectPolarity(in s: String) -> Polarity {
        let tokens = s.split { !$0.isLetter }.map(String.init)
        var pos = 0, neg = 0
        for t in tokens {
            if posWords.contains(t) { pos += 1 }
            if negWords.contains(t) { neg += 1 }
        }
        if pos == 0 && neg == 0 { return .neutral }
        if pos > 0 && neg > 0   { return .mixed }
        return pos > neg ? .positive : .negative
    }

    // MARK: - util

    private static func matches(_ s: String, any phrases: [String]) -> Bool {
        for p in phrases {
            if s.contains(p) { return true }
        }
        return false
    }
}
