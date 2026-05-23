import XCTest
@testable import TeluguRiddles

@MainActor
final class RiddleProgressStoreTests: XCTestCase {
    func testRecordsCorrectAndWrongAnswers() {
        let store = makeStore()

        store.recordAttempt(isCorrect: true, date: date(2026, 5, 21))
        store.recordAttempt(isCorrect: false, date: date(2026, 5, 21))

        XCTAssertEqual(store.correctAnswerCount, 1)
        XCTAssertEqual(store.wrongAnswerCount, 1)
        XCTAssertEqual(store.currentStreak, 1)
        XCTAssertEqual(store.longestStreak, 1)
    }

    func testDailyStreakIncrementsOncePerDay() {
        let store = makeStore()

        store.recordAttempt(isCorrect: true, date: date(2026, 5, 21))
        store.recordAttempt(isCorrect: true, date: date(2026, 5, 21, hour: 20))
        store.recordAttempt(isCorrect: true, date: date(2026, 5, 22))

        XCTAssertEqual(store.correctAnswerCount, 3)
        XCTAssertEqual(store.currentStreak, 2)
        XCTAssertEqual(store.longestStreak, 2)
    }

    func testClearAnswerStatsLeavesStatsEmpty() {
        let store = makeStore()

        store.recordAttempt(isCorrect: true, date: date(2026, 5, 21))
        store.recordAttempt(isCorrect: false, date: date(2026, 5, 21))
        store.clearAnswerStats()

        XCTAssertEqual(store.correctAnswerCount, 0)
        XCTAssertEqual(store.wrongAnswerCount, 0)
        XCTAssertEqual(store.currentStreak, 0)
        XCTAssertEqual(store.longestStreak, 0)
        XCTAssertFalse(store.hasAnswerStats)
    }

    private func makeStore() -> RiddleProgressStore {
        let suiteName = "TeluguRiddlesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return RiddleProgressStore(defaults: defaults, calendar: calendar)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
