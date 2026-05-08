import XCTest
@testable import Lull

final class SeededRandomTests: XCTestCase {

    func testSameSeedProducesSameSequence() {
        var a = SeededRandom(seed: 42)
        var b = SeededRandom(seed: 42)
        for _ in 0..<100 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testDifferentSeedsDiverge() {
        var a = SeededRandom(seed: 1)
        var b = SeededRandom(seed: 2)
        let first = (a.next(), b.next())
        XCTAssertNotEqual(first.0, first.1)
    }

    func testPickReturnsFromPool() {
        var rng = SeededRandom(seed: 99)
        let pool = ["a", "b", "c", "d", "e"]
        for _ in 0..<50 {
            XCTAssertTrue(pool.contains(rng.pick(pool)))
        }
    }

    func testZeroSeedIsHandled() {
        var rng = SeededRandom(seed: 0)
        let v = rng.next()
        XCTAssertNotEqual(v, 0)
    }

    func testHasherStable() {
        let h1 = SeedHasher.hash("a", "b", "c")
        let h2 = SeedHasher.hash("a", "b", "c")
        XCTAssertEqual(h1, h2)
        XCTAssertNotEqual(h1, SeedHasher.hash("a", "b", "d"))
    }
}
