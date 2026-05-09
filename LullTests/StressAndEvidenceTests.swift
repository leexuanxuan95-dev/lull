import XCTest
@testable import Lull

/// Belt-and-suspenders tests: print the actual combinatoric numbers so the
/// claim is auditable, and stress-test the engines with thousands of seeds
/// to catch any latent slot-leak / fill-failure / non-determinism the unit
/// tests didn't trip on.
final class StressAndEvidenceTests: XCTestCase {

    // MARK: - Hard-evidence printout

    func testPrintCombinatoricEvidence() {
        let storyTotal = StoryGenerator.totalCombinations
        let chatTotal  = CompanionChat.totalReplyCombinations

        // Logged via XCTest so the value shows up in the build log.
        print("===== COMBINATORIC EVIDENCE =====")
        print(String(format: "Story total combinations: %.3e", storyTotal))
        print(String(format: "Chat reply combinations:  %.3e", chatTotal))
        for genre in Genre.allCases {
            let c = StoryGrammar.combinations(for: genre)
            print(String(format: "  %-20@ %.3e", genre.rawValue as NSString, c))
        }
        print("================================")

        XCTAssertGreaterThan(storyTotal, 1_000_000_000)
        XCTAssertGreaterThan(chatTotal,  100_000_000)
    }

    // MARK: - Stress: 1000 random stories, no leaks, no crashes

    func testStressOneThousandStories() {
        var leakCount = 0
        var emptyCount = 0
        for i in 0..<1000 {
            let genre = Genre.allCases[i % Genre.allCases.count]
            let req = StoryRequest(
                genre: genre,
                userName: ["Augis", "Maya", "Sam", "", "玛雅"][i % 5],
                userCity: ["Vilnius", "Lisbon", "Kyoto", "", "北京"][i % 5],
                userActivity: ["walking", "reading", "tea", "", ""][i % 5],
                seed: UInt64(i) &* 0x9E37_79B9_7F4A_7C15
            )
            let story = StoryGenerator.generate(req)
            for p in story.paragraphs {
                if p.contains("{") || p.contains("[?") { leakCount += 1 }
                if p.isEmpty { emptyCount += 1 }
            }
        }
        XCTAssertEqual(leakCount, 0, "Found \(leakCount) unresolved slots across 1000 stories.")
        XCTAssertEqual(emptyCount, 0, "Found \(emptyCount) empty paragraphs across 1000 stories.")
    }

    // MARK: - Stress: 1000 random chat replies, no leaks, no crashes

    func testStressOneThousandReplies() {
        let messages = [
            "hi", "hello", "I can't sleep", "I'm anxious", "scared",
            "tell me a story", "good night", "thanks",
            "I'm worried about my deadline", "my chest is tight",
            "ok", "today was good", "I miss someone",
            "I'm freezing", "I'm sweating", "the world feels heavy",
            "my back hurts", "I just need quiet", "make it stop",
            "yeah", "the news is bad", "kids won't sleep",
            "money is tight", "future feels uncertain", "I keep regretting things",
            "everything is wrong", "I cant stop thinking", "racing thoughts",
            "exhausted", "wired", "is it too late?"
        ]
        let profiles = [
            UserStoryProfile(displayName: "Augis", displayCity: "Vilnius", displayActivity: "walks"),
            UserStoryProfile(displayName: "玛雅",   displayCity: "上海",    displayActivity: "茶"),
            UserStoryProfile.placeholder
        ]
        var leakCount = 0
        var emptyCount = 0
        var unique = Set<String>()
        for i in 0..<1000 {
            let msg = messages[i % messages.count]
            let profile = profiles[i % profiles.count]
            let reply = CompanionChat.reply(
                to: msg,
                profile: profile,
                extraEntropy: "stress-\(i)"
            )
            if reply.contains("{") || reply.contains("[?") { leakCount += 1 }
            if reply.isEmpty { emptyCount += 1 }
            unique.insert(reply)
        }
        XCTAssertEqual(leakCount, 0, "Found \(leakCount) unresolved slots in 1000 replies.")
        XCTAssertEqual(emptyCount, 0, "Found \(emptyCount) empty replies in 1000 calls.")
        // 1000 calls with varied messages + entropy should produce hundreds of distinct replies.
        XCTAssertGreaterThan(unique.count, 300,
            "Only \(unique.count) distinct replies in 1000 calls — variety regressed.")
        print("Stress: 1000 replies, \(unique.count) distinct.")
    }

    // MARK: - Determinism property: same input → same output, byte-for-byte

    func testDeterminismProperty() {
        for seed in stride(from: UInt64(0), through: UInt64(50), by: 1) {
            let req = StoryRequest(genre: .villageWalk,
                                   userName: "X", userCity: "Y", userActivity: "Z",
                                   seed: seed)
            let a = StoryGenerator.generate(req)
            let b = StoryGenerator.generate(req)
            XCTAssertEqual(a.fullText, b.fullText, "Determinism broke at seed \(seed)")
        }
        let profile = UserStoryProfile.placeholder
        for i in 0..<50 {
            let r1 = CompanionChat.reply(to: "I'm anxious",
                                         profile: profile,
                                         extraEntropy: "det-\(i)")
            let r2 = CompanionChat.reply(to: "I'm anxious",
                                         profile: profile,
                                         extraEntropy: "det-\(i)")
            XCTAssertEqual(r1, r2, "Chat determinism broke at iter \(i)")
        }
    }
}
