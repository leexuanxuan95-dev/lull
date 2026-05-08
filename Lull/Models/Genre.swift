import Foundation

enum Genre: String, CaseIterable, Codable, Identifiable, Equatable {
    case villageWalk
    case cozySciFi
    case gentleMystery
    case natureDoc

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .villageWalk:   return "Old Village Walk"
        case .cozySciFi:     return "Cozy Sci-Fi"
        case .gentleMystery: return "Gentle Mystery"
        case .natureDoc:     return "Nature Doc"
        }
    }

    var emoji: String {
        switch self {
        case .villageWalk:   return "🏘️"
        case .cozySciFi:     return "🚀"
        case .gentleMystery: return "🔍"
        case .natureDoc:     return "🌳"
        }
    }

    var tagline: String {
        switch self {
        case .villageWalk:   return "stone streets, low lamps, the long way home"
        case .cozySciFi:     return "a small ship, a kind crew, a sleeping galaxy"
        case .gentleMystery: return "a clue is found. nothing is solved tonight."
        case .natureDoc:     return "the forest at the edge of waking"
        }
    }
}
