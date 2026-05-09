import XCTest
@testable import Lull

final class CompanionChatTests: XCTestCase {

    // MARK: combinatoric space

    /// The reply grammar must produce at least 100 million distinct replies —
    /// the user-facing "上亿种回复" / "hundreds of millions of replies" claim.
    /// We use a real lower bound (slot products walked, not estimated).
    func testReplyCombinatoricSpaceExceedsHundredMillion() {
        XCTAssertGreaterThan(CompanionChat.totalReplyCombinations,
                             100_000_000,
                             "Chat grammar should produce > 100M unique replies.")
    }

    // MARK: intent detection

    func testGreetIntent() {
        let a = MessageAnalyzer.analyze("hi")
        XCTAssertEqual(a.intent, .greet)
    }

    func testFarewellIntent() {
        XCTAssertEqual(MessageAnalyzer.analyze("goodnight").intent, .farewell)
        XCTAssertEqual(MessageAnalyzer.analyze("good night").intent, .farewell)
    }

    func testAnxiousIntent() {
        XCTAssertEqual(MessageAnalyzer.analyze("I'm so anxious tonight").intent, .anxious)
    }

    func testCantSleepIntent() {
        XCTAssertEqual(MessageAnalyzer.analyze("I can't sleep").intent, .cantSleep)
    }

    func testOverthinkingIntent() {
        XCTAssertEqual(MessageAnalyzer.analyze("my mind is racing thoughts").intent, .overthinking)
    }

    func testWorriedAboutWork() {
        let a = MessageAnalyzer.analyze("I'm stressed about a meeting tomorrow")
        XCTAssertEqual(a.intent, .worried)
        XCTAssertEqual(a.topic, .work)
    }

    func testGratefulIntent() {
        XCTAssertEqual(MessageAnalyzer.analyze("today was actually a good day").intent, .grateful)
    }

    func testRequestStory() {
        XCTAssertEqual(MessageAnalyzer.analyze("can you tell me a story please").intent, .requestStory)
    }

    func testRequestBreathing() {
        XCTAssertEqual(MessageAnalyzer.analyze("help me breathe").intent, .requestBreathing)
    }

    // MARK: reply quality

    func testRepliesAreNonEmpty() {
        let profile = UserStoryProfile.placeholder
        for sample in [
            "hi", "I can't sleep", "anxious", "worried about work",
            "thanks", "goodnight", "tell me a story", "I miss someone",
            "I'm sad", "scared", "ok", "today was okay actually",
            "the world feels heavy", "my back hurts", "I'm freezing"
        ] {
            let reply = CompanionChat.reply(to: sample, profile: profile)
            XCTAssertFalse(reply.isEmpty, "Empty reply for: \(sample)")
            XCTAssertFalse(reply.contains("{"),
                "Unresolved slot in reply to '\(sample)': \(reply)")
            XCTAssertFalse(reply.contains("[?"),
                "Unresolved slot key in reply to '\(sample)': \(reply)")
        }
    }

    func testRepliesPersonalize() {
        let profile = UserStoryProfile(displayName: "Maya",
                                       displayCity: "Athens",
                                       displayActivity: "swimming")
        var foundName = false
        for i in 0..<40 {
            let reply = CompanionChat.reply(to: "I can't sleep",
                                            profile: profile,
                                            extraEntropy: "\(i)")
            if reply.contains("Maya") { foundName = true; break }
        }
        XCTAssertTrue(foundName, "Across 40 calls at least one reply should include the name.")
    }

    func testRepliesVaryAcrossCalls() {
        let profile = UserStoryProfile.placeholder
        let replies = (0..<20).map { i in
            CompanionChat.reply(to: "I'm anxious",
                                profile: profile,
                                extraEntropy: "\(i)")
        }
        XCTAssertGreaterThan(Set(replies).count, 5,
            "20 calls with different entropy should yield at least 5 unique replies.")
    }

    // MARK: body state

    func testHotBodyStateAddsAdvice() {
        let profile = UserStoryProfile.placeholder
        var sawHotAdvice = false
        for i in 0..<25 {
            let reply = CompanionChat.reply(to: "I'm so hot, can't sleep",
                                            profile: profile,
                                            extraEntropy: "\(i)")
            if reply.lowercased().contains("blanket") || reply.lowercased().contains("cool") || reply.lowercased().contains("wrist") {
                sawHotAdvice = true
                break
            }
        }
        XCTAssertTrue(sawHotAdvice)
    }

    // MARK: topic-specific worry

    func testWorkWorryAddsWorkAcknowledgement() {
        let profile = UserStoryProfile.placeholder
        var sawWorkAck = false
        for i in 0..<20 {
            let reply = CompanionChat.reply(to: "stressed about my deadline at work",
                                            profile: profile,
                                            extraEntropy: "\(i)").lowercased()
            if reply.contains("work") || reply.contains("job") || reply.contains("deadline") || reply.contains("meeting") {
                sawWorkAck = true
                break
            }
        }
        XCTAssertTrue(sawWorkAck, "Work-topic worry should at least sometimes mention work.")
    }
}
