import Foundation

@MainActor
final class RiddleProgressStore: ObservableObject {
    @Published private(set) var favoriteIDs: Set<Int>
    @Published private(set) var seenIDs: Set<Int>
    @Published private(set) var correctAnswerCount: Int
    @Published private(set) var wrongAnswerCount: Int
    @Published private(set) var currentStreak: Int
    @Published private(set) var longestStreak: Int

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let favoritesKey = "favoriteRiddleIDs"
    private let seenKey = "seenRiddleIDs"
    private let correctAnswerCountKey = "correctAnswerCount"
    private let wrongAnswerCountKey = "wrongAnswerCount"
    private let currentStreakKey = "currentAnswerStreak"
    private let longestStreakKey = "longestAnswerStreak"
    private let lastCorrectDateKey = "lastCorrectAnswerDate"
    private var lastCorrectDate: Date?

    var hasAnswerStats: Bool {
        correctAnswerCount > 0 || wrongAnswerCount > 0 || currentStreak > 0 || longestStreak > 0
    }

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        favoriteIDs = Self.loadSet(from: defaults, key: favoritesKey)
        seenIDs = Self.loadSet(from: defaults, key: seenKey)
        correctAnswerCount = defaults.integer(forKey: correctAnswerCountKey)
        wrongAnswerCount = defaults.integer(forKey: wrongAnswerCountKey)
        currentStreak = defaults.integer(forKey: currentStreakKey)
        longestStreak = defaults.integer(forKey: longestStreakKey)
        lastCorrectDate = defaults.object(forKey: lastCorrectDateKey) as? Date
    }

    func isFavorite(_ riddle: Riddle) -> Bool {
        favoriteIDs.contains(riddle.id)
    }

    func toggleFavorite(_ riddle: Riddle) {
        if favoriteIDs.contains(riddle.id) {
            favoriteIDs.remove(riddle.id)
        } else {
            favoriteIDs.insert(riddle.id)
        }
        save(favoriteIDs, key: favoritesKey)
    }

    func markSeen(_ riddle: Riddle) {
        guard !seenIDs.contains(riddle.id) else { return }
        seenIDs.insert(riddle.id)
        save(seenIDs, key: seenKey)
    }

    func clearSeen() {
        seenIDs.removeAll()
        save(seenIDs, key: seenKey)
    }

    func recordAttempt(isCorrect: Bool, date: Date = Date()) {
        if isCorrect {
            correctAnswerCount += 1
            updateStreak(for: date)
        } else {
            wrongAnswerCount += 1
        }

        saveAnswerStats()
    }

    func clearAnswerStats() {
        correctAnswerCount = 0
        wrongAnswerCount = 0
        currentStreak = 0
        longestStreak = 0
        lastCorrectDate = nil
        defaults.removeObject(forKey: lastCorrectDateKey)
        saveAnswerStats()
    }

    private func save(_ ids: Set<Int>, key: String) {
        defaults.set(Array(ids).sorted(), forKey: key)
    }

    private func updateStreak(for date: Date) {
        if let lastCorrectDate {
            if calendar.isDate(date, inSameDayAs: lastCorrectDate) {
                longestStreak = max(longestStreak, currentStreak)
                return
            }

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastCorrectDate),
               calendar.isDate(date, inSameDayAs: nextDay) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastCorrectDate = date
        longestStreak = max(longestStreak, currentStreak)
    }

    private func saveAnswerStats() {
        defaults.set(correctAnswerCount, forKey: correctAnswerCountKey)
        defaults.set(wrongAnswerCount, forKey: wrongAnswerCountKey)
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(longestStreak, forKey: longestStreakKey)
        defaults.set(lastCorrectDate, forKey: lastCorrectDateKey)
    }

    private static func loadSet(from defaults: UserDefaults, key: String) -> Set<Int> {
        Set(defaults.array(forKey: key) as? [Int] ?? [])
    }
}
