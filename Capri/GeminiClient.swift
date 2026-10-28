import Foundation

enum CloudError: Error {
    case auth
    case geo
    case limit
    case network
    case empty
    case api(String)

    var line: String {
        switch self {
        case .auth:
            return "Ключ не тот, солнце. Загляни в настройки и вставь нормальный."
        case .geo:
            return "Google меня не пускает из этой сети: нужен VPN. Включи его — и я снова в деле."
        case .limit:
            return "Меня притормозили: бесплатный лимит, блин. Дай минуту и пиши снова."
        case .network:
            return "Сеть легла. Я скучаю, но ответить не могу. Проверь интернет."
        case .empty:
            return "Я зависла на полуслове. Спроси ещё раз, а?"
        case .api(let detail):
            return "Что-то хрустнуло: \(detail). Попробуй ещё раз."
        }
    }
}

/// Клиент Gemini через OpenAI-совместимый эндпоинт — тот же, что у настольной Капри.
struct GeminiClient {
    var key: String = Config.apiKey
    var baseURL: String = Config.baseURL
    var model: String = Config.model
    var timeout: TimeInterval = 12

    private var models: [String] {
        let fallbacks = ["gemini-3.6-flash", "gemini-2.5-flash"]
        return [model] + fallbacks.filter { $0 != model }
    }

    func reply(system: String, history: [ChatMessage]) async throws -> String {
        var last: CloudError = .empty
        for candidate in models {
            do {
                return try await once(candidate, system: system, history: history)
            } catch let error as CloudError {
                last = error
                switch error {
                case .limit:
                    // бесплатный лимит: короткая пауза и следующая модель
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    if Task.isCancelled { throw CancellationError() }
                case .api, .empty:
                    break
                case .auth, .geo, .network:
                    throw error
                }
            }
        }
        throw last
    }

    private func once(_ model: String, system: String, history: [ChatMessage]) async throws -> String {
        let includeReasoning = !model.lowercased().contains("lite")
        do {
            return try await call(model, system: system, history: history, reasoning: includeReasoning)
        } catch let error as CloudError {
            if case .api(let detail) = error, detail.contains("reasoning_effort") || detail.contains("invalid argument") {
                // не всем моделям Gemini нравится отключение «размышлений»
                return try await call(model, system: system, history: history, reasoning: false)
            }
            throw error
        }
    }

    private func call(_ model: String, system: String, history: [ChatMessage], reasoning: Bool) async throws -> String {
        guard !key.isEmpty else { throw CloudError.auth }
        guard let url = URL(string: baseURL + "/chat/completions") else { throw CloudError.api("неверный адрес API") }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("Capri-iOS/1.0", forHTTPHeaderField: "User-Agent")

        var messages: [[String: String]] = [["role": "system", "content": system]]
        for message in history.suffix(14) {
            messages.append([
                "role": message.role == .user ? "user" : "assistant",
                "content": message.text
            ])
        }

        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.75,
            "max_tokens": 400,
            "stream": false
        ]
        if reasoning {
            body["reasoning_effort"] = "none"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2
        let session = URLSession(configuration: configuration)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            session.invalidateAndCancel()
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            session.invalidateAndCancel()
            throw CancellationError()
        } catch {
            session.invalidateAndCancel()
            throw CloudError.network
        }
        session.invalidateAndCancel()

        guard let http = response as? HTTPURLResponse else { throw CloudError.network }
        let raw = String(data: data, encoding: .utf8) ?? ""

        if http.statusCode == 429 { throw CloudError.limit }
        if raw.contains("location is not supported") || raw.contains("FAILED_PRECONDITION") {
            throw CloudError.geo
        }
        if http.statusCode == 401 || http.statusCode == 403 { throw CloudError.auth }
        if http.statusCode == 400 {
            if raw.contains("API key") || raw.contains("API_KEY") { throw CloudError.auth }
            throw CloudError.api(short(raw, fallback: "HTTP 400"))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CloudError.api(short(raw, fallback: "HTTP \(http.statusCode)"))
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let json = object as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw CloudError.empty
        }
        return content
    }

    private func short(_ raw: String, fallback: String) -> String {
        let clean = raw.replacingOccurrences(of: "\n", with: " ")
        if clean.isEmpty { return fallback }
        return String(clean.prefix(120))
    }
}
