import Foundation

/// Tiny JSON-on-disk store for things too rich for `@AppStorage`:
/// generated stories cache and chat history. UserDefaults keeps the
/// user profile + flags.
@MainActor
final class LullVault: ObservableObject {

    static let shared = LullVault()

    private let queue = DispatchQueue(label: "lull.vault", qos: .utility)
    private let fm = FileManager.default

    @Published private(set) var stories: [GeneratedStory] = []
    @Published private(set) var chat: [ChatMessage] = []

    private var storiesURL: URL { docsURL.appendingPathComponent("stories.json") }
    private var chatURL: URL    { docsURL.appendingPathComponent("chat.json") }

    private var docsURL: URL {
        if let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
        return fm.temporaryDirectory
    }

    private init() {
        load()
    }

    // MARK: - load/save

    private func load() {
        if let data = try? Data(contentsOf: storiesURL),
           let decoded = try? JSONDecoder.lullDefault.decode([GeneratedStory].self, from: data) {
            self.stories = decoded
        }
        if let data = try? Data(contentsOf: chatURL),
           let decoded = try? JSONDecoder.lullDefault.decode([ChatMessage].self, from: data) {
            self.chat = decoded
        }
    }

    private func persistStories() {
        let snapshot = stories
        let url = storiesURL
        queue.async {
            if let data = try? JSONEncoder.lullDefault.encode(snapshot) {
                try? data.write(to: url, options: [.atomic])
            }
        }
    }

    private func persistChat() {
        let snapshot = chat
        let url = chatURL
        queue.async {
            if let data = try? JSONEncoder.lullDefault.encode(snapshot) {
                try? data.write(to: url, options: [.atomic])
            }
        }
    }

    // MARK: - stories

    func addStory(_ story: GeneratedStory) {
        stories.insert(story, at: 0)
        if stories.count > 30 { stories = Array(stories.prefix(30)) }
        persistStories()
    }

    func recentStory(for genre: Genre) -> GeneratedStory? {
        stories.first(where: { $0.genre == genre })
    }

    // MARK: - chat

    func appendChat(_ msg: ChatMessage) {
        chat.append(msg)
        if chat.count > 200 { chat.removeFirst(chat.count - 200) }
        persistChat()
    }

    func clearChat() {
        chat.removeAll()
        persistChat()
    }
}

extension JSONEncoder {
    static let lullDefault: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}

extension JSONDecoder {
    static let lullDefault: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
