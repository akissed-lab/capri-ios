import Foundation

/// Настройки в UserDefaults. Ключи те же, что читают экраны настроек через @AppStorage.
enum Config {
    private static var defaults: UserDefaults { .standard }

    static var apiKey: String {
        get { defaults.string(forKey: "capri_api_key") ?? "" }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capri_api_key") }
    }

    static var baseURL: String {
        get {
            let value = (defaults.string(forKey: "capri_base_url") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "https://generativelanguage.googleapis.com/v1beta/openai" : value
        }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capri_base_url") }
    }

    static var model: String {
        get {
            let value = (defaults.string(forKey: "capri_model") ?? "").trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? "gemini-3.5-flash-lite" : value
        }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespaces), forKey: "capri_model") }
    }

    static var ttsOn: Bool {
        get { defaults.object(forKey: "capri_tts") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "capri_tts") }
    }

    static var pitch: Double {
        get { defaults.object(forKey: "capri_pitch") as? Double ?? 1.22 }
        set { defaults.set(newValue, forKey: "capri_pitch") }
    }

    static var notificationsOn: Bool {
        get { defaults.object(forKey: "capri_notif") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "capri_notif") }
    }

    static var intensity: Double {
        get { defaults.object(forKey: "capri_intensity") as? Double ?? 0.6 }
        set { defaults.set(newValue, forKey: "capri_intensity") }
    }

    static var userName: String {
        get { defaults.string(forKey: "capri_name") ?? "" }
        set { defaults.set(newValue, forKey: "capri_name") }
    }

    static var keyConfigured: Bool { !apiKey.isEmpty }
}
