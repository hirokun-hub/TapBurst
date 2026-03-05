import Foundation

final class ScoreStore {
    private static let bestScoreKey = "bestScore"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var bestScore: Int {
        get {
            defaults.integer(forKey: Self.bestScoreKey)
        }
        set {
            defaults.set(newValue, forKey: Self.bestScoreKey)
        }
    }

    @discardableResult
    func updateIfNeeded(score: Int) -> Bool {
        guard score > bestScore else {
            return false
        }

        bestScore = score
        return true
    }
}
