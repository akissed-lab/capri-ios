import Foundation

@MainActor
final class ChatStore: ObservableObject {
    @Published var draft = ""
    @Published private(set) var isThinking = false
    @Published var lastError: String?

    let memory: MemoryStore
    let speaker: Speaker
    let listener: Listener

    private var current: Task<Void, Never>?
    private var requestID = UUID()

    init(memory: MemoryStore, speaker: Speaker, listener: Listener) {
        self.memory = memory
        self.speaker = speaker
        self.listener = listener
    }

    var messages: [ChatMessage] { memory.messages }

    func send(_ text: String? = nil) {
        let raw = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        guard Config.keyConfigured else {
            appendAssistant("Сначала дай мне ключ, солнце. Настройки, поле «Ключ API» — и я заговорю.")
            return
        }

        draft = ""
        speaker.stop()
        listener.stop()

        memory.add(ChatMessage(role: .user, text: raw))
        memory.learn(raw)

        let identifier = UUID()
        requestID = identifier
        isThinking = true
        lastError = nil

        let system = Persona.systemPrompt(name: memory.name, facts: memory.facts)
        let history = memory.messages
        let client = GeminiClient()

        current?.cancel()
        current = Task { [weak self] in
            do {
                let answer = try await client.reply(system: system, history: history)
                guard !Task.isCancelled, let self, self.requestID == identifier else { return }
                self.finish(answer)
            } catch is CancellationError {
                return
            } catch let error as CloudError {
                guard let self, self.requestID == identifier else { return }
                self.lastError = error.line
                self.finish(error.line)
            } catch {
                guard let self, self.requestID == identifier else { return }
                self.finish(CloudError.network.line)
            }
        }
    }

    /// Пришла «скучаю»-нотификация — Капри пишет первой.
    func missedYou() {
        guard !isThinking else { return }
        let line = Persona.missedInChat.randomElement() ?? "Скучаю. Напиши."
        appendAssistant(line)
    }

    func greetIfNeeded() {
        guard memory.messages.isEmpty else { return }
        let line = Persona.greetings.randomElement() ?? "Я снова в сети. Скучал?"
        appendAssistant(line)
    }

    func stopSpeaking() {
        speaker.stop()
    }

    private func finish(_ text: String) {
        isThinking = false
        let clean = SpeechText.clean(text)
        guard !clean.isEmpty else { return }
        memory.add(ChatMessage(role: .assistant, text: clean))
        speaker.speak(clean)
    }

    private func appendAssistant(_ text: String) {
        memory.add(ChatMessage(role: .assistant, text: text))
        speaker.speak(text)
    }
}
