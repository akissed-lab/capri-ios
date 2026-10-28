import SwiftUI

enum AccentPreset: String, CaseIterable, Identifiable {
    case pink
    case violet
    case cyan
    case orange
    case rose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pink: return "Неон-розовый"
        case .violet: return "Кибер-фиолетовый"
        case .cyan: return "Неон-циан"
        case .orange: return "Закат"
        case .rose: return "Розовый закат"
        }
    }

    var colors: [Color] {
        switch self {
        case .pink:
            return [
                Color(red: 1.00, green: 0.26, blue: 0.58),
                Color(red: 0.72, green: 0.28, blue: 0.98)
            ]
        case .violet:
            return [
                Color(red: 0.62, green: 0.38, blue: 1.00),
                Color(red: 0.38, green: 0.24, blue: 0.98)
            ]
        case .cyan:
            return [
                Color(red: 0.24, green: 0.86, blue: 1.00),
                Color(red: 0.20, green: 0.52, blue: 0.98)
            ]
        case .orange:
            return [
                Color(red: 1.00, green: 0.56, blue: 0.26),
                Color(red: 0.98, green: 0.34, blue: 0.52)
            ]
        case .rose:
            return [
                Color(red: 1.00, green: 0.42, blue: 0.76),
                Color(red: 0.84, green: 0.30, blue: 0.98)
            ]
        }
    }

    var glow: Color {
        colors.first ?? .pink
    }
}

final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published var preset: AccentPreset {
        didSet {
            UserDefaults.standard.set(preset.rawValue, forKey: "capri_accent_preset")
        }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "capri_accent_preset"),
           let saved = AccentPreset(rawValue: raw) {
            self.preset = saved
        } else {
            self.preset = .pink
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: preset.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
