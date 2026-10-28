import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    enum Role: String, Codable {
        case user
        case assistant
    }

    var id: UUID
    var role: Role
    var text: String
    var date: Date

    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.date = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, role, text, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        role = try container.decode(Role.self, forKey: .role)
        text = try container.decode(String.self, forKey: .text)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }
}

/// Память: имя, факты о пользователе и переписка. Всё лежит локально на телефоне.
@MainActor
final class MemoryStore: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var facts: [String] = []
    @Published var name: String = Config.userName {
        didSet {
            Config.userName = name
            save()
        }
    }

    private struct Snapshot: Codable {
        var name: String
        var facts: [String]
        var messages: [ChatMessage]
    }

    private let storeURL: URL = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("capri-chat.json")
    }()

    init() {
        load()
    }

    func add(_ message: ChatMessage) {
        messages.append(message)
        if messages.count > 300 {
            messages.removeFirst(messages.count - 300)
        }
        save()
    }

    /// Учится на фразах вроде «меня зовут Ярослав», «я люблю пиццу».
    func learn(_ original: String) {
        let text = original.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        for marker in ["меня зовут ", "моё имя ", "мое имя "] {
            if let range = text.range(of: marker, options: .caseInsensitive) {
                let tail = text[range.upperBound...]
                let first = tail.split(separator: " ").first.map(String.init) ?? ""
                let clean = first.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:«»\"()"))
                if clean.count >= 2 && clean.count <= 24 {
                    name = clean.prefix(1).uppercased() + String(clean.dropFirst())
                }
                break
            }
        }

        let factsMap: [(String, String)] = [
            ("я люблю ", "любит "),
            ("я ненавижу ", "ненавидит "),
            ("я работаю ", "работает "),
            ("у меня есть ", "у него есть "),
            ("мой день рождения ", "день рождения ")
        ]
        for (marker, replacement) in factsMap {
            if text.range(of: marker, options: [.caseInsensitive, .anchored]) != nil {
                let value = String(text.dropFirst(marker.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                guard value.count >= 2 else { continue }
                addFact(replacement + value)
            }
        }
    }

    func addFact(_ fact: String) {
        let clean = fact.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        if facts.contains(where: { $0.caseInsensitiveCompare(clean) == .orderedSame }) {
            return
        }
        facts.append(clean)
        if facts.count > 30 {
            facts.removeFirst(facts.count - 30)
        }
        save()
    }

    func removeFact(at index: Int) {
        guard facts.indices.contains(index) else { return }
        facts.remove(at: index)
        save()
    }

    func reset() {
        messages = []
        facts = []
        name = ""
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        messages = snapshot.messages
        facts = snapshot.facts
        if !snapshot.name.isEmpty {
            name = snapshot.name
        }
    }

    private func save() {
        let snapshot = Snapshot(name: name, facts: facts, messages: Array(messages.suffix(300)))
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
