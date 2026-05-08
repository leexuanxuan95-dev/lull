import Foundation
import AVFoundation
import Combine

/// Wraps `AVSpeechSynthesizer` so the rest of the app doesn't have to know
/// about utterances. Uses on-device system voices (no network, no API keys).
///
/// The four "base voices" in `VoiceProfile.baseVoices` are mapped at runtime
/// to whichever installed AVSpeechSynthesisVoice best matches their requested
/// gender/locale. The mapping is forgiving — we always fall back to the
/// device's default English voice rather than erroring.
@MainActor
final class VoiceEngine: NSObject, ObservableObject {

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var paragraphIndex: Int = 0
    @Published private(set) var totalParagraphs: Int = 0

    /// Fired when the last paragraph finishes. The listening view uses this
    /// to drive the auto-fade-out and "story complete" state.
    let didFinish = PassthroughSubject<Void, Never>()

    private let synth = AVSpeechSynthesizer()
    private var queue: [String] = []
    private var currentVoice: VoiceProfile = VoiceProfile.baseVoices[0]

    override init() {
        super.init()
        synth.delegate = self
        configureAudioSession()
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback,
                                    mode: .spokenAudio,
                                    options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            // Best-effort — the simulator sometimes refuses session activation
            // when no audio HW is available; speech synthesis still works.
        }
    }

    // MARK: - Playback

    func play(story: GeneratedStory, voice: VoiceProfile) {
        stop()
        self.currentVoice = voice
        self.queue = story.paragraphs
        self.paragraphIndex = 0
        self.totalParagraphs = story.paragraphs.count
        speakNextIfNeeded()
    }

    func pause() {
        if synth.isSpeaking, !synth.isPaused {
            synth.pauseSpeaking(at: .immediate)
            isPlaying = false
        }
    }

    func resume() {
        if synth.isPaused {
            synth.continueSpeaking()
            isPlaying = true
        }
    }

    func stop() {
        if synth.isSpeaking || synth.isPaused {
            synth.stopSpeaking(at: .immediate)
        }
        queue.removeAll()
        paragraphIndex = 0
        totalParagraphs = 0
        isPlaying = false
    }

    // MARK: - Internals

    private func speakNextIfNeeded() {
        guard !queue.isEmpty else {
            isPlaying = false
            didFinish.send(())
            return
        }
        let next = queue.removeFirst()
        let utterance = AVSpeechUtterance(string: next)
        utterance.voice = resolveAVVoice(for: currentVoice)
        utterance.rate = currentVoice.rate
        utterance.pitchMultiplier = currentVoice.pitch
        utterance.preUtteranceDelay = paragraphIndex == 0 ? 0.6 : 1.2
        utterance.postUtteranceDelay = 1.0
        utterance.volume = 1.0
        synth.speak(utterance)
        isPlaying = true
    }

    private func resolveAVVoice(for profile: VoiceProfile) -> AVSpeechSynthesisVoice {
        // 1) try by direct identifier (Pro+ clones use a real voice ID).
        if let v = AVSpeechSynthesisVoice(identifier: profile.id) { return v }

        // 2) pick by language, prefer enhanced quality, then prefer the matching gender.
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { ($0.quality.rawValue) > ($1.quality.rawValue) }

        let preferred: AVSpeechSynthesisVoiceGender = {
            switch profile.preferredGender {
            case .female:  return .female
            case .male:    return .male
            case .neutral: return .unspecified
            }
        }()

        if let match = voices.first(where: { $0.gender == preferred }) { return match }
        if let any = voices.first { return any }
        if let en = AVSpeechSynthesisVoice(language: "en-US") { return en }
        if let any = AVSpeechSynthesisVoice.speechVoices().first { return any }

        // Practically unreachable on iOS — speechVoices() always returns at
        // least the system default. Force-unwrap the device's own language
        // as a last resort and document why.
        return AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())!
    }
}

extension VoiceEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.paragraphIndex += 1
            self.speakNextIfNeeded()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
