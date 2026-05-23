import Foundation

@MainActor
final class RiddleStore: ObservableObject {
    @Published private(set) var riddles: [Riddle] = []
    @Published private(set) var categories: [String] = []

    init() {
        load()
    }

    func riddles(in category: String?) -> [Riddle] {
        guard let category, category != "అన్ని" else {
            return riddles.shuffled()
        }

        return riddles.filter { $0.category == category }.shuffled()
    }

    func riddles(in category: String?, excludingSeen seenIDs: Set<Int>) -> [Riddle] {
        let selected = riddles(in: category)
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
