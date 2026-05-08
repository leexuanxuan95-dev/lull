import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    // ── persisted user profile ──
    @AppStorage("lull.didOnboard")    var didOnboard: Bool = false
    @AppStorage("lull.userName")      var userName: String = ""
    @AppStorage("lull.userCity")      var userCity: String = ""
    @AppStorage("lull.userActivity")  var userActivity: String = ""

    // ── persisted user preferences ──
    @AppStorage("lull.voiceID")       var selectedVoiceID: String = VoiceProfile.baseVoices[0].id
    @AppStorage("lull.sleepTimerRaw") var sleepTimerRaw: String = SleepDetector.Mode.untilAsleep.rawValue
    @AppStorage("lull.smartWakeOn")   var smartWakeOn: Bool = false
    @AppStorage("lull.smartWakeHour") var smartWakeHour: Int = 7
    @AppStorage("lull.smartWakeMin")  var smartWakeMinute: Int = 0
    @AppStorage("lull.cloneSetup")    var hasCloneVoice: Bool = false

    // ── ephemeral nav state ──
    @Published var listeningStory: GeneratedStory?
    @Published var paywallPresented: Bool = false

    // ── owned engines ──
    let subscription = SubscriptionStore()
    let voiceEngine  = VoiceEngine()
    let vault        = LullVault.shared
    let sleepTimer   = SleepDetector()

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Mirror subscription tier into a tiny computed flag if needed.
        subscription.$tier
            .sink { _ in /* downstream views observe `isPro` directly */ }
            .store(in: &cancellables)
    }

    // ── derived ──

    var profile: UserStoryProfile {
        UserStoryProfile(
            displayName:     userName.isEmpty ? "friend" : userName,
            displayCity:     userCity.isEmpty ? "this city" : userCity,
            displayActivity: userActivity.isEmpty ? "your slow evening habit" : userActivity
        )
    }

    var selectedVoice: VoiceProfile {
        VoiceProfile.allBuiltIn.first(where: { $0.id == selectedVoiceID })
            ?? VoiceProfile.baseVoices[0]
    }

    var sleepTimerMode: SleepDetector.Mode {
        get { SleepDetector.Mode(rawValue: sleepTimerRaw) ?? .untilAsleep }
        set { sleepTimerRaw = newValue.rawValue }
    }

    var isPro:     Bool { subscription.isPro }
    var isProPlus: Bool { subscription.isProPlus }

    // ── intents ──

    /// Build "tonight's story" for the chosen genre. If we already generated
    /// one for today/this genre, return it; otherwise generate, cache, return.
    func ensureTonightStory(for genre: Genre) -> GeneratedStory {
        let seed = StoryGenerator.nightlySeed(date: Date(),
                                              name: profile.displayName,
                                              city: profile.displayCity,
                                              genre: genre)

        if let cached = vault.recentStory(for: genre), cached.seed == seed {
            return cached
        }

        let req = StoryRequest(
            genre: genre,
            userName: profile.displayName,
            userCity: profile.displayCity,
            userActivity: profile.displayActivity,
            seed: seed
        )
        let story = StoryGenerator.generate(req)
        vault.addStory(story)
        return story
    }

    /// Begin playback. Always picks the latest selected voice.
    func startListening(_ story: GeneratedStory) {
        listeningStory = story
        sleepTimer.mode = sleepTimerMode
        sleepTimer.start()
        voiceEngine.play(story: story, voice: selectedVoice)
    }

    func stopListening() {
        voiceEngine.stop()
        sleepTimer.stop()
        listeningStory = nil
    }
}
