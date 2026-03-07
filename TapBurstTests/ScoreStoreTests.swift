import Testing
import Foundation
@testable import TapBurst

struct ScoreStoreTests {

    @Test("T-020: initial best score is 0")
    func initialBestScore_isZero() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)

        #expect(store.bestScore == 0)
    }

    @Test("T-020: updateIfNeeded returns true and updates when score is higher")
    func updateIfNeeded_higherScore_updatesAndReturnsTrue() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 42

        let didUpdate = store.updateIfNeeded(score: 50)

        #expect(didUpdate)
        #expect(store.bestScore == 50)
    }

    @Test("T-020: updateIfNeeded returns false and keeps value when score is lower")
    func updateIfNeeded_lowerScore_keepsExistingValue() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 42

        let didUpdate = store.updateIfNeeded(score: 41)

        #expect(!didUpdate)
        #expect(store.bestScore == 42)
    }

    // MARK: - Today Best Score

    @Test("todayBestScore is initially 0")
    func todayBestScore_initiallyZero() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)

        #expect(store.todayBestScore == 0)
    }

    @Test("updateTodayIfNeeded returns true and updates when score is higher")
    func updateTodayIfNeeded_higherScore_updates() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)

        let didUpdate = store.updateTodayIfNeeded(score: 50)

        #expect(didUpdate)
        #expect(store.todayBestScore == 50)
    }

    @Test("updateTodayIfNeeded returns false and keeps when score is lower")
    func updateTodayIfNeeded_lowerScore_keeps() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.updateTodayIfNeeded(score: 50)

        let didUpdate = store.updateTodayIfNeeded(score: 30)

        #expect(!didUpdate)
        #expect(store.todayBestScore == 50)
    }

    @Test("todayBestScore resets on new day")
    func todayBestScore_resetsOnNewDay() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayStore = ScoreStore(defaults: defaults) { yesterday }
        yesterdayStore.updateTodayIfNeeded(score: 100)

        let todayStore = ScoreStore(defaults: defaults) { Date() }

        #expect(todayStore.todayBestScore == 0)
    }

    // MARK: - Reset All

    @Test("resetAll clears both scores")
    func resetAll_clearsBothScores() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 100
        store.updateTodayIfNeeded(score: 80)

        store.resetAll()

        #expect(store.bestScore == 0)
        #expect(store.todayBestScore == 0)
    }

    @Test("resetAll allows subsequent updates")
    func resetAll_allowsSubsequentUpdates() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 100
        store.updateTodayIfNeeded(score: 80)

        store.resetAll()

        let didUpdateBest = store.updateIfNeeded(score: 30)
        let didUpdateToday = store.updateTodayIfNeeded(score: 20)

        #expect(didUpdateBest)
        #expect(store.bestScore == 30)
        #expect(didUpdateToday)
        #expect(store.todayBestScore == 20)
    }

    private func testDefaults() -> (UserDefaults, String) {
        let suiteName = "TapBurstTests.ScoreStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
