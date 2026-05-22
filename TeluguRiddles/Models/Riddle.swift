import Foundation

struct Riddle: Identifiable, Codable, Equatable {
    let id: Int
    let category: String
    let difficulty: String
    let question: String
    let answer: String
    let hint: String
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

    var title: String {
        switch self {
        case .ten: return "10"
        case .twenty: return "20"
        case .thirty: return "30"
        case .endless: return "అంతులేని"
        }
    }
}
