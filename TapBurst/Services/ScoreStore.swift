import Foundation

final class ScoreStore {
    private static let bestScoreKey = "bestScore"
    private static let todayBestScoreKey = "todayBestScore"
    private static let todayBestDateKey = "todayBestDate"

    private let defaults: UserDefaults
    private let dateProvider: () -> Date

    init(defaults: UserDefaults = .standard, dateProvider: @escaping () -> Date = { Date() }) {
        self.defaults = defaults
        self.dateProvider = dateProvider
    }

    var bestScore: Int {
        get {
            defaults.integer(forKey: Self.bestScoreKey)
        }
        set {
            defaults.set(newValue, forKey: Self.bestScoreKey)
        }
    }

    var todayBestScore: Int {
        guard let savedDate = defaults.object(forKey: Self.todayBestDateKey) as? Date,
              Calendar.current.isDate(savedDate, inSameDayAs: dateProvider()) else {
            return 0
        }
        return defaults.integer(forKey: Self.todayBestScoreKey)
    }

    @discardableResult
    func updateIfNeeded(score: Int) -> Bool {
        guard score > bestScore else {
            return false
        }

        bestScore = score
        return true
    }

    @discardableResult
    func updateTodayIfNeeded(score: Int) -> Bool {
        guard score > todayBestScore else {
            return false
        }
        defaults.set(score, forKey: Self.todayBestScoreKey)
        defaults.set(dateProvider(), forKey: Self.todayBestDateKey)
        return true
    }

    func resetAll() {
        defaults.removeObject(forKey: Self.bestScoreKey)
        defaults.removeObject(forKey: Self.todayBestScoreKey)
        defaults.removeObject(forKey: Self.todayBestDateKey)
    }
}
