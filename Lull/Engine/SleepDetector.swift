import Foundation
import Combine

/// "When are they asleep?" — answered with a *fallback* timer because the
/// simulator has no HealthKit sleep data. On a real device we'd hook the
/// `HKObserverQuery` for `categoryTypeIdentifier(.sleepAnalysis)` and fade
/// the story out 5 minutes after the first non-awake stage; in the absence
/// of that, the user picks a sleep timer and we honor it.
///
/// The point of having this class at all is so the rest of the app talks
/// to *one* surface for "fade the story now please," regardless of how the
/// device decided that.
@MainActor
final class SleepDetector: ObservableObject {

    enum Mode: String, CaseIterable, Identifiable, Codable {
        case fifteen, thirty, fortyFive, sixty, untilAsleep
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .fifteen:    return "15 min"
            case .thirty:     return "30 min"
            case .fortyFive:  return "45 min"
            case .sixty:      return "1 hour"
            case .untilAsleep: return "Until I'm asleep"
            }
        }

        /// Hard cap in seconds. `.untilAsleep` falls back to 60 min on the
        /// simulator since we can't actually detect sleep there.
        var capSeconds: TimeInterval {
            switch self {
            case .fifteen:    return 15 * 60
            case .thirty:     return 30 * 60
            case .fortyFive:  return 45 * 60
            case .sixty:      return 60 * 60
            case .untilAsleep: return 60 * 60
            }
        }
    }

    @Published var mode: Mode = .untilAsleep
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var shouldFadeOut: Bool = false

    private var timer: Timer?

    func start() {
        stop()
        elapsed = 0
        shouldFadeOut = false
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        elapsed = 0
        shouldFadeOut = false
    }

    private func tick() {
        elapsed += 1
        if elapsed >= mode.capSeconds {
            shouldFadeOut = true
            timer?.invalidate()
            timer = nil
        }
    }
}
