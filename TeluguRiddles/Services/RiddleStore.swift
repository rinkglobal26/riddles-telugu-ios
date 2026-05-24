import Foundation

@MainActor
final class RiddleStore: ObservableObject {
    @Published private(set) var riddles: [Riddle] = []
    @Published private(set) var categories: [String] = []

    init() {
        load()
    }

    func riddles(in category: String?, level: RiddleLevel = .shuffle) -> [Riddle] {
        let categoryFiltered: [Riddle]

        if let category, category != "అన్ని" {
            categoryFiltered = riddles.filter { $0.category == category }
        } else {
            categoryFiltered = riddles
        }

        guard level != .shuffle else {
            return categoryFiltered.shuffled()
        }

        let difficultyValues = level.difficultyValues
        let levelFiltered = categoryFiltered
            .filter { difficultyValues.contains($0.difficulty) || difficultyValues.contains($0.englishDifficulty) }

        return levelFiltered.isEmpty ? categoryFiltered.shuffled() : levelFiltered.shuffled()
    }

    func riddles(in category: String?, level: RiddleLevel = .shuffle, excludingSeen seenIDs: Set<Int>) -> [Riddle] {
        let selected = riddles(in: category, level: level)
        let fresh = selected.filter { !seenIDs.contains($0.id) }
        return fresh.isEmpty ? selected : fresh
    }

    func title(for category: String, mode: LanguageMode, allTitle: String) -> String {
        guard category != "అన్ని" else { return allTitle }
        guard mode.usesEnglishChrome else { return category }
        return riddles.first { $0.category == category }?.englishCategory ?? category
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "riddles", withExtension: "json") else {
            riddles = []
            categories = ["అన్ని"]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            riddles = try JSONDecoder().decode([Riddle].self, from: data)
            categories = ["అన్ని"] + Array(Set(riddles.map(\.category))).sorted()
        } catch {
            riddles = []
            categories = ["అన్ని"]
        }
    }
}
