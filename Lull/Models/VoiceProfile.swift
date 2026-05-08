import Foundation

/// A choosable narrator voice. Maps to an AVSpeechSynthesisVoice via identifier
/// where possible; for the four base voices we resolve at runtime to whichever
/// English-locale voice on the device best matches the requested temperament.
struct VoiceProfile: Codable, Identifiable, Equatable, Hashable {
    let id: String                  // e.g. "soft.female", "soft.male"
    let displayName: String
    let isPro: Bool
    let isClone: Bool               // true for Pro+ user-clone voices
    let preferredGender: PreferredGender
    let rate: Float                 // 0.0–1.0 mapped onto AVSpeechUtterance.rate
    let pitch: Float                // 0.5–2.0
    let detail: String              // shown under the name on the picker

    enum PreferredGender: String, Codable {
        case female, male, neutral
    }

    static let baseVoices: [VoiceProfile] = [
        VoiceProfile(id: "soft.female", displayName: "Calm — Female",
                     isPro: false, isClone: false, preferredGender: .female,
                     rate: 0.40, pitch: 0.95,
                     detail: "warm, evening-timed"),
        VoiceProfile(id: "soft.male",   displayName: "Calm — Male",
                     isPro: false, isClone: false, preferredGender: .male,
                     rate: 0.39, pitch: 0.85,
                     detail: "low, unhurried"),
        VoiceProfile(id: "neutral",     displayName: "Neutral",
                     isPro: false, isClone: false, preferredGender: .neutral,
                     rate: 0.41, pitch: 1.00,
                     detail: "even, library-quiet"),
        VoiceProfile(id: "whisper",     displayName: "Library Whisper",
                     isPro: false, isClone: false, preferredGender: .neutral,
                     rate: 0.36, pitch: 0.92,
                     detail: "the slowest of the four")
    ]

    static let proVoices: [VoiceProfile] = [
        VoiceProfile(id: "pro.deep",     displayName: "Deep Calm",
                     isPro: true, isClone: false, preferredGender: .male,
                     rate: 0.36, pitch: 0.78, detail: "deepest base voice"),
        VoiceProfile(id: "pro.warm",     displayName: "Warm Lamp",
                     isPro: true, isClone: false, preferredGender: .female,
                     rate: 0.39, pitch: 1.00, detail: "honey-warm tone"),
        VoiceProfile(id: "pro.evening",  displayName: "Evening Reader",
                     isPro: true, isClone: false, preferredGender: .neutral,
                     rate: 0.42, pitch: 0.95, detail: "narrator-paced"),
        VoiceProfile(id: "pro.lullaby",  displayName: "Lullaby",
                     isPro: true, isClone: false, preferredGender: .female,
                     rate: 0.34, pitch: 1.05, detail: "slowest, sing-song-soft")
    ]

    static var allBuiltIn: [VoiceProfile] { baseVoices + proVoices }
}
