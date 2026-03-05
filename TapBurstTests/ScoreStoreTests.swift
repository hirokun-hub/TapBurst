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

    private func testDefaults() -> (UserDefaults, String) {
        let suiteName = "TapBurstTests.ScoreStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
