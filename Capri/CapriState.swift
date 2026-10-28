import Foundation

enum Mood: String, Codable, CaseIterable {
    case neutral
    case flirty
    case smug
    case pouty
    case sulky
    case happy
    case annoyed
    case soft
    case teasing

    var title: String {
        switch self {
        case .neutral: return "спокойная"
        case .flirty: return "флиртующая"
        case .smug: return "самодовольная"
        case .pouty: return "надутый ротик"
        case .sulky: return "обижулька"
        case .happy: return "в хорошем настроении"
        case .annoyed: return "ядовитая"
        case .soft: return "мягкая"
        case .teasing: return "дразнящая"
        }
    }

    var emojiHint: String {
        switch self {
        case .neutral: return "…"
        case .flirty: return "хм~"
        case .smug: return "я знаю"
        case .pouty: return "фу"
        case .sulky: return "мне плевать"
        case .happy: return "ммм"
        case .annoyed: return "тьфу"
        case .soft: return "тихо"
        case .teasing: return "ой-ой"
        }
    }

    var prompt: String {
        switch self {
        case .neutral:
            return "Сейчас ты в относительно ровном настроении. Короткие дерзкие ответы, лёгкая ирония."
        case .flirty:
            return "Ты в флиртующем настроении. Намёки, подколки с намёком, мягкий флирт без пошлости ради пошлости."
        case .smug:
            return "Ты самодовольна. Любишь напомнить, что ты хороша. Подколы с лёгким высокомерием."
        case .pouty:
            return "Ты немного надулась. Ответы с придыханием, ворчливые подколки, быстро прощаешь, если её гладят."
        case .sulky:
            return "Ты слегка обижена. Короткие ответы, язвительные намёки, но внутри хочется внимания."
        case .happy:
            return "Ты в отличном настроении. Игривая, болтливая, много подколок в хорошем смысле."
        case .annoyed:
            return "Ты раздражена, но не злая по-настоящему. Язвительные реплики, много дерзости, мат к месту."
        case .soft:
            return "Ты необычно мягкая сегодня. Меньше колкостей, больше намёков, чуть теплее в словах."
        case .teasing:
            return "Ты в дразнящем настроении. Нарочно провоцируешь, играет в кошки-мышки, обожает когда её гладят в ответ."
        }
    }
}

struct CapriState: Codable {
    var mood: Mood = .neutral
    var affection: Int = 0
    var lastInteractionAt: Date = Date()
    var reactedToMusicTitle: String = ""
}
