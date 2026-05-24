import Foundation

struct Riddle: Identifiable, Codable, Equatable {
    let id: Int
    let category: String
    let englishCategory: String
    let difficulty: String
    let englishDifficulty: String
    let question: String
    let englishQuestion: String
    let answer: String
    let englishAnswer: String
    let hint: String
    let englishHint: String

    func category(for mode: LanguageMode) -> String {
        mode.usesEnglishChrome ? englishCategory : category
    }

    func difficulty(for mode: LanguageMode) -> String {
        mode.usesEnglishChrome ? englishDifficulty : difficulty
    }

    func question(for mode: LanguageMode) -> String {
        mode.usesEnglishRiddles ? englishQuestion : question
    }

    func answer(for mode: LanguageMode) -> String {
        mode.usesEnglishRiddles ? englishAnswer : answer
    }

    func hint(for mode: LanguageMode) -> String {
        mode.usesEnglishRiddles ? englishHint : hint
    }
}

struct GameTeam: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var score: Int = 0
}

enum GameLength: Int, CaseIterable, Identifiable {
    case ten = 10
    case twenty = 20
    case thirty = 30
    case endless = 0

    var id: Int { rawValue }

    func title(for mode: LanguageMode) -> String {
        switch self {
        case .ten: return "10"
        case .twenty: return "20"
        case .thirty: return "30"
        case .endless: return mode.usesEnglishChrome ? "Endless" : "అంతులేని"
        }
    }
}

enum LanguageMode: String, CaseIterable, Identifiable {
    case telugu
    case hybrid
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .telugu: return "తెలుగు"
        case .hybrid: return "Hybrid"
        case .english: return "English"
        }
    }

    var usesEnglishChrome: Bool {
        self == .hybrid || self == .english
    }

    var usesEnglishRiddles: Bool {
        self == .english
    }
}

enum PlayMode: String, CaseIterable, Identifiable {
    case solo
    case teams

    var id: String { rawValue }

    func title(for mode: LanguageMode) -> String {
        switch self {
        case .solo: return mode.usesEnglishChrome ? "Solo" : "ఒంటరిగా"
        case .teams: return mode.usesEnglishChrome ? "Teams" : "జట్లు"
        }
    }
}

enum RiddleLevel: String, CaseIterable, Identifiable {
    case shuffle
    case easy
    case medium
    case hard

    var id: String { rawValue }

    func title(for mode: LanguageMode) -> String {
        switch self {
        case .shuffle: return mode.usesEnglishChrome ? "Shuffle" : "కలిపి"
        case .easy: return mode.usesEnglishChrome ? "Easy" : "సులువు"
        case .medium: return mode.usesEnglishChrome ? "Medium" : "మధ్యస్థం"
        case .hard: return mode.usesEnglishChrome ? "Hard" : "కష్టం"
        }
    }

    var difficultyValues: Set<String> {
        switch self {
        case .shuffle:
            return []
        case .easy:
            return ["సులువు", "Easy"]
        case .medium:
            return ["మధ్యస్థం", "Medium"]
        case .hard:
            return ["చురుకు", "Quick", "Hard", "కష్టం"]
        }
    }

    var systemImage: String {
        switch self {
        case .shuffle: return "shuffle"
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }
}
