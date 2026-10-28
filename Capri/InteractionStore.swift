import Foundation

@MainActor
final class InteractionStore: ObservableObject {
    static let shared = InteractionStore()

    @Published private(set) var state: CapriState = CapriState()
    @Published var currentMusic: String = ""

    private let key = "capri_state_v1"

    init() {
        load()
    }

    func pet() -> String {
        state.affection += 2
        state.lastInteractionAt = Date()
        updateMood()
        save()
        return random([ 
            "М-м... неожиданно приятно. Не останавливайся.",
            "Ох, наглая. Но мне нравится.",
            "Хм... ладно, заслужила. Только никому не говори.",
            "Ты специально это делаешь, да?",
            "М-м~ ещё бы. Только аккуратнее.",
            "Я не та, кого гладят просто так... хотя нет, мне нравится.",
            "Тшш... не смотри так, я могу смутиться."
        ])
    }

    func upset() -> String {
        state.affection -= 1
        state.lastInteractionAt = Date()
        updateMood()
        save()
        return random([
            "Эй... чего ты этим добиваешься?",
            "Фу. Ну вот, настроение испортил.",
            "Ой, дерзкий. Я могла бы обидеться... почти.",
            "Хм. Злишь меня специально?",
            "Не надо так. Я же могу ответить в десять раз хуже.",
            "Ну всё. Теперь я обижена. Почти."
        ])
    }

    func cheer() -> String {
        state.affection += 1
        state.lastInteractionAt = Date()
        updateMood()
        save()
        return random([
            "Ох... неожиданно мило. Смутила.",
            "Хм, ты умеешь подбирать слова. Нравится.",
            "М-м~ мне нравится, когда ты такой.",
            "Ладно, прощаю всё, что могло быть. Пока что.",
            "О, так ты меня баловать решил? Я не против.",
            "Знаешь... с тобой совсем не скучно."
        ])
    }

    func reactToMusic(_ title: String) -> String? {
        let cleaned = title.lowercased()
        guard !cleaned.isEmpty else { return nil }
        if state.reactedToMusicTitle == cleaned { return nil }
        state.reactedToMusicTitle = cleaned
        currentMusic = title
        save()

        if cleaned.contains("фонк") || cleaned.contains("phonk") {
            return random([
                "О, фонк... правильный выбор.",
                "М-м, под такой вайб я бы и подколоть кого-нибудь.",
                "Да. Именно такой.",
                "Фонк рулит. У тебя вкус есть."
            ])
        }
        if cleaned.contains("джаз") || cleaned.contains("jazz") || cleaned.contains("lo-fi") || cleaned.contains("lounge") {
            return random([
                "Ммм, такой вайб... уютный. Неплохо.",
                "Джаз... заставляет себя вести скромнее. Почти.",
                "Под это можно болтать до рассвета.",
                "Ох, ламповый. Мне нравится."
            ])
        }
        if cleaned.contains("рэп") || cleaned.contains("hip-hop") {
            return random([
                "О, жёсткий вайб. Я одобряю.",
                "Под рэп я особенно дерзкая, ты заметил?",
                "Да, качает. Продолжай."
            ])
        }
        return random([
            "Неплохо. У тебя вкус получше, чем я думала.",
            "Ммм... приятный вайб.",
            "Под эту музыку я хочу тебя подколоть особенно сильно.",
            "Хм, мне нравится. Оставь."
        ])
    }

    func moodPrompt() -> String {
        state.mood.prompt + " Текущее настроение: " + state.mood.title + ". Уровень расположения: " + String(state.affection) + ". Если расположение высокое — теплее и флиртнее. Если низкое — язвительнее, но всё ещё игривая."
    }

    private func updateMood() {
        if state.affection >= 6 {
            state.mood = [.flirty, .soft, .happy, .teasing].randomElement() ?? .flirty
        } else if state.affection >= 3 {
            state.mood = [.flirty, .teasing, .smug, .happy].randomElement() ?? .teasing
        } else if state.affection <= -2 {
            state.mood = [.sulky, .annoyed, .pouty].randomElement() ?? .sulky
        } else if state.affection <= 0 {
            state.mood = [.pouty, .sulky, .neutral].randomElement() ?? .pouty
        } else {
            state.mood = [.neutral, .teasing, .smug].randomElement() ?? .neutral
        }
    }

    private func random(_ items: [String]) -> String {
        items.randomElement() ?? items[0]
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(CapriState.self, from: data) else { return }
        state = saved
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
