import Foundation

struct GameSession {
    private(set) var teams: [GameTeam]
    private(set) var currentIndex = 0
    private(set) var activeTeamIndex = 0
    private(set) var completedRounds = 0

    let riddles: [Riddle]
    let gameLength: GameLength

    init(riddles: [Riddle], gameLength: GameLength, teams: [GameTeam]) {
        self.riddles = riddles
        self.gameLength = gameLength
        self.teams = teams
    }

    var currentRiddle: Riddle? {
        riddles.indices.contains(currentIndex) ? riddles[currentIndex] : nil
    }

    var isFinished: Bool {
        gameLength != .endless && completedRounds >= gameLength.rawValue
    }

    var progressText: String {
        progressText(for: .telugu)
    }

    func progressText(for mode: LanguageMode) -> String {
        if gameLength == .endless {
            return mode.usesEnglishChrome ? "Round \(completedRounds + 1)" : "రౌండ్ \(completedRounds + 1)"
        }
        let prefix = mode.usesEnglishChrome ? "Round" : "రౌండ్"
        return "\(prefix) \(min(completedRounds + 1, gameLength.rawValue)) / \(gameLength.rawValue)"
    }

    var activeTeamName: String {
        teams[safe: activeTeamIndex]?.name ?? "జట్టు"
    }

    mutating func advance(scored: Bool) {
        if scored, teams.indices.contains(activeTeamIndex) {
            teams[activeTeamIndex].score += 1
        }

        completedRounds += 1

        guard !isFinished else { return }

        currentIndex = (currentIndex + 1) % max(riddles.count, 1)
        activeTeamIndex = (activeTeamIndex + 1) % max(teams.count, 1)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
