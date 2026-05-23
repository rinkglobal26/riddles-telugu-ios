import Foundation
import UserNotifications

@MainActor
final class DailyRiddleNotifier: ObservableObject {
    @Published private(set) var authorizationDenied = false

    private static let identifierPrefix = "daily-riddle-"
    private static let scheduledDays = 30

    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(center: UNUserNotificationCenter = .current(), calendar: Calendar = .current) {
        self.center = center
        self.calendar = calendar
    }

    func scheduleDailyRiddles(from riddles: [Riddle], mode: LanguageMode) async -> Bool {
        guard !riddles.isEmpty else { return false }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                authorizationDenied = true
                cancelDailyRiddles()
                return false
            }

            authorizationDenied = false
            cancelDailyRiddles()

            let firstOffset = nextNotificationIsToday() ? 0 : 1
            for dayOffset in 0..<Self.scheduledDays {
                let targetOffset = dayOffset + firstOffset
                guard
                    let date = calendar.date(byAdding: .day, value: targetOffset, to: Date()),
                    let riddle = Self.riddleOfTheDay(from: riddles, date: date, calendar: calendar)
                else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = mode.usesEnglishChrome ? "Riddle of the Day" : "ఈరోజు పొడుపు"
                content.body = riddle.question(for: mode)
                content.sound = .default

                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = 19
                components.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(Self.identifierPrefix)\(dayOffset)",
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }

            return true
        } catch {
            authorizationDenied = true
            return false
        }
    }

    func cancelDailyRiddles() {
        let identifiers = (0..<Self.scheduledDays).map { "\(Self.identifierPrefix)\($0)" } + ["daily-riddle"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func riddleOfTheDay(from riddles: [Riddle], date: Date, calendar: Calendar) -> Riddle? {
        guard !riddles.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return riddles[day % riddles.count]
    }

    private func nextNotificationIsToday() -> Bool {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 0

        guard let todayAtSeven = calendar.date(from: components) else { return false }
        return Date() < todayAtSeven
    }
}
