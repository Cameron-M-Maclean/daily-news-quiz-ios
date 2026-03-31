import Foundation
import Combine

struct StatChanges {
    let streakBefore: Int
    let streakAfter: Int
    let percentageBefore: Double?  // nil on first ever quiz
    let percentageAfter: Double
}

class StatsManager: ObservableObject {
    @Published private(set) var currentStreak: Int
    @Published private(set) var answeredCorrectlyPercentage: Double
    @Published private(set) var hasStats: Bool

    private let defaults = UserDefaults.standard
    private enum Key {
        static let streak = "streak"
        static let lastCompleted = "lastCompletedDate"
        static let totalAnswered = "totalAnswered"
        static let totalCorrect = "totalCorrect"
    }

    init() {
        let totalAnswered = defaults.integer(forKey: Key.totalAnswered)
        let totalCorrect = defaults.double(forKey: Key.totalCorrect)
        currentStreak = defaults.integer(forKey: Key.streak)
        hasStats = totalAnswered > 0
        answeredCorrectlyPercentage = totalAnswered > 0
            ? totalCorrect / Double(totalAnswered) * 100
            : 0
    }

    // Records a completed quiz and returns the before/after changes for display.
    func recordCompletion(correct: Double, total: Int) -> StatChanges {
        let previousStreak = currentStreak
        let totalAnswered = defaults.integer(forKey: Key.totalAnswered)

        let previousPercentage: Double? = totalAnswered > 0
            ? defaults.double(forKey: Key.totalCorrect) / Double(totalAnswered) * 100
            : nil

        let newTotalAnswered = totalAnswered + total
        let newTotalCorrect = defaults.double(forKey: Key.totalCorrect) + correct
        defaults.set(newTotalAnswered, forKey: Key.totalAnswered)
        defaults.set(newTotalCorrect, forKey: Key.totalCorrect)
        let newPercentage = newTotalCorrect / Double(newTotalAnswered) * 100

        let newStreak = updatedStreak()

        currentStreak = newStreak
        answeredCorrectlyPercentage = newPercentage
        hasStats = true

        return StatChanges(
            streakBefore: previousStreak,
            streakAfter: newStreak,
            percentageBefore: previousPercentage,
            percentageAfter: newPercentage
        )
    }

    private func updatedStreak() -> Int {
        let today = Calendar.current.startOfDay(for: Date())

        guard let lastDate = defaults.object(forKey: Key.lastCompleted) as? Date else {
            // First ever completion
            defaults.set(1, forKey: Key.streak)
            defaults.set(today, forKey: Key.lastCompleted)
            return 1
        }

        let lastDay = Calendar.current.startOfDay(for: lastDate)

        if lastDay == today {
            return currentStreak  // already completed today, no change
        }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let newStreak = lastDay == yesterday ? currentStreak + 1 : 1
        defaults.set(newStreak, forKey: Key.streak)
        defaults.set(today, forKey: Key.lastCompleted)
        return newStreak
    }
}
