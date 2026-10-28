import AVFoundation
import Speech

/// Слушает микрофон и отдаёт распознанный текст через onFinish.
@MainActor
final class Listener: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var transcript = ""
    @Published var error: String?

    var onFinish: ((String) -> Void)?

    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapInstalled = false

    func start() async {
        guard !isRecording else { return }
        guard let recognizer else {
            error = "Русское распознавание речи на этом телефоне недоступно."
            return
        }
        guard await microphoneAllowed() else {
            error = "Нет доступа к микрофону. Разреши его в настройках iOS."
            return
        }
        guard await speechAllowed() else {
            error = "Разреши распознавание речи в настройках iOS."
            return
        }
        guard recognizer.isAvailable else {
            error = "Распознавание сейчас недоступно. Попробуй ещё раз."
            return
        }

        error = nil
        transcript = ""

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .dictation
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            tapInstalled = true
            engine.prepare()
            try engine.start()
            isRecording = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                        if result.isFinal {
                            self.finish()
                            return
                        }
                    }
                    if error != nil {
                        self.finish()
                    }
                }
            }
        } catch {
            self.error = "Микрофон не запустился: \(error.localizedDescription)"
            finish()
        }
    }

    func stop() {
        guard isRecording else { return }
        finish()
    }

    private func finish() {
        if engine.isRunning {
            engine.stop()
        }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        transcript = ""
        if !text.isEmpty {
            onFinish?(text)
        }
    }

    private func microphoneAllowed() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func speechAllowed() async -> Bool {
        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        return status == .authorized
    }
}
