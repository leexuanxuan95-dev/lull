import XCTest
@testable import Lull

final class StoryGeneratorTests: XCTestCase {

    // MARK: combinatoric space

    /// The grammar must produce more than one billion distinct stories
    /// across all genres — the product's "AI-feel without an LLM" claim.
    func testCombinatoricSpaceExceedsOneBillion() {
        XCTAssertGreaterThan(StoryGenerator.totalCombinations,
                             1_000_000_000,
                             "Story grammar should produce > 1B unique stories.")
    }

    func testEachGenreProducesNonTrivialSpace() {
        for genre in Genre.allCases {
            XCTAssertGreaterThan(StoryGrammar.combinations(for: genre),
                                 1_000_000,
                                 "Genre \(genre.rawValue) should give > 1M variants.")
        }
    }

    // MARK: determinism

    /// Same seed → exactly the same story. Required for "tonight's story"
    /// to feel stable across pause/resume.
    func testSameSeedSameStory() {
        let req = StoryRequest(genre: .villageWalk,
                               userName: "Augis",
                               userCity: "Vilnius",
                               userActivity: "long walks",
                               seed: 12345)
        let a = StoryGenerator.generate(req)
        let b = StoryGenerator.generate(req)
        XCTAssertEqual(a.title, b.title)
        XCTAssertEqual(a.paragraphs, b.paragraphs)
    }

    func testDifferentSeedsLikelyDifferent() {
        let base = StoryRequest(genre: .villageWalk,
                                userName: "Augis", userCity: "Vilnius",
                                userActivity: "reading", seed: 1)
        let stories = (1...20).map { i in
            StoryGenerator.generate(StoryRequest(
                genre: base.genre, userName: base.userName, userCity: base.userCity,
                userActivity: base.userActivity, seed: UInt64(i * 1000 + 7)))
        }
        let unique = Set(stories.map(\.fullText))
        XCTAssertGreaterThanOrEqual(unique.count, 10,
            "20 different seeds should produce at least 10 distinct stories.")
    }

    // MARK: slot resolution

    /// No `{slot}` markers should leak into final prose.
    func testNoUnresolvedSlots() {
        for genre in Genre.allCases {
            let req = StoryRequest(genre: genre,
                                   userName: "Sam", userCity: "Kyoto",
                                   userActivity: "tea ceremony",
                                   seed: SeedHasher.hash("slot-leak", genre.rawValue))
            let story = StoryGenerator.generate(req)
            for paragraph in story.paragraphs {
                XCTAssertFalse(paragraph.contains("{"),
                               "Found unresolved slot in: \(paragraph)")
                XCTAssertFalse(paragraph.contains("[?"),
                               "Found unresolved slot key in: \(paragraph)")
            }
        }
    }

    func testProfileSlotsSubstituted() {
        let req = StoryRequest(genre: .gentleMystery,
                               userName: "Maria",
                               userCity: "Lisbon",
                               userActivity: "swimming",
                               seed: SeedHasher.hash("slot-substitution"))
        let story = StoryGenerator.generate(req)
        let full = story.fullText
        XCTAssertTrue(full.contains("Maria"))
        XCTAssertTrue(full.contains("Lisbon"))
    }

    /// Empty profile fields must be replaced by sensible defaults — no
    /// "Hi, !" or "the streets of ." artifacts.
    func testEmptyProfileGetsDefaults() {
        let req = StoryRequest(genre: .natureDoc,
                               userName: "", userCity: "", userActivity: "",
                               seed: 42)
        let story = StoryGenerator.generate(req)
        for paragraph in story.paragraphs {
            XCTAssertFalse(paragraph.contains(", ,"),
                           "Empty slot left a punctuation artifact: \(paragraph)")
            XCTAssertFalse(paragraph.contains("  "),
                           "Empty slot left double spaces: \(paragraph)")
        }
    }

    // MARK: shape

    func testStoryHasMultipleParagraphs() {
        for genre in Genre.allCases {
            let req = StoryRequest(genre: genre, userName: "X", userCity: "Y",
                                   userActivity: "Z", seed: 999)
            let story = StoryGenerator.generate(req)
            XCTAssertGreaterThanOrEqual(story.paragraphs.count, 5,
                "\(genre.rawValue) story should have at least 5 scenes")
        }
    }

    func testEstimatedDurationInTargetRange() {
        let req = StoryRequest(genre: .villageWalk, userName: "X", userCity: "Y",
                               userActivity: "Z", seed: 1)
        let story = StoryGenerator.generate(req)
        XCTAssertGreaterThanOrEqual(story.estimatedDurationMinutes, 15)
        XCTAssertLessThanOrEqual(story.estimatedDurationMinutes, 25)
    }

    // MARK: nightly seed stability

    func testNightlySeedStableWithinDay() {
        let now = Date()
        let s1 = StoryGenerator.nightlySeed(date: now, name: "A", city: "B", genre: .cozySciFi)
        let s2 = StoryGenerator.nightlySeed(date: now.addingTimeInterval(60),
                                            name: "A", city: "B", genre: .cozySciFi)
        XCTAssertEqual(s1, s2)
    }
}
