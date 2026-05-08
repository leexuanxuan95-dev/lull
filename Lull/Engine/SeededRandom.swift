import Foundation

/// Deterministic SplitMix64 PRNG. Same seed → same sequence forever.
/// Used so that "tonight's story" is reproducible: a user opening the same
/// genre on the same date always gets the same words, which matters for
/// pause/resume and for not pulling the rug out from under someone's
/// half-asleep listening session.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0xCAFEBABE_DEADBEEF
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func pick<T>(_ pool: [T]) -> T {
        precondition(!pool.isEmpty, "Cannot pick from empty pool")
        let idx = Int(next() % UInt64(pool.count))
        return pool[idx]
    }

    mutating func pickIndex(_ count: Int) -> Int {
        precondition(count > 0)
        return Int(next() % UInt64(count))
    }
}

enum SeedHasher {
    /// Stable hash of arbitrary string bytes. Used to derive a seed from
    /// (date, name, city, genre) without relying on Swift's `String.hashValue`,
    /// which is randomised per process launch.
    static func hash(_ parts: String...) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for part in parts {
            for byte in part.utf8 {
                h ^= UInt64(byte)
                h &*= 0x100_0000_01B3
            }
            h ^= 0x5A
            h &*= 0x9E37_79B9_7F4A_7C15
        }
        return h
    }
}
