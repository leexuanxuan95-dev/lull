import Foundation

struct StoryRequest: Equatable {
    let genre: Genre
    let userName: String
    let userCity: String
    let userActivity: String
    let seed: UInt64
}

struct GeneratedStory: Codable, Identifiable, Equatable {
    let id: UUID
    let genre: Genre
    let title: String
    let paragraphs: [String]
    let estimatedDurationMinutes: Int
    let createdAt: Date
    let seed: UInt64

    var fullText: String { paragraphs.joined(separator: "\n\n") }
}
