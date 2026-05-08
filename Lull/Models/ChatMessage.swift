import Foundation

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {
    enum Role: String, Codable, Equatable, Hashable {
        case user, companion
    }

    let id: UUID
    let role: Role
    let body: String
    let createdAt: Date

    init(id: UUID = UUID(), role: Role, body: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.body = body
        self.createdAt = createdAt
    }
}
