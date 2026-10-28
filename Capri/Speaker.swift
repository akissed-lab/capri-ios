import AVFoundation

/// Голос Капри: системный русский голос с поднятым тоном — свой тембр вместо «робота из настроек».
@MainActor
final class Speaker: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        guard Config.ttsOn else { return }
        let clean = SpeechText.clean(text)
        guard !clean.isEmpty else { return }

        stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: clean)
        utterance.voice = preferredVoice()
        utterance.pitchMultiplier = Float(max(0.5, min(2.0, Config.pitch)))
        utterance.rate = 0.5
        utterance.preUtteranceDelay = 0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let russian = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("ru") }
        if let premium = russian.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = russian.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "ru-RU")
    }
}

extension Speaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
