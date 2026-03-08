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
        let playedAt = Date(timeIntervalSince1970: 1234)

        let didUpdate = store.updateIfNeeded(score: 50, cps: 5.0, playedAt: playedAt)

        #expect(didUpdate)
        #expect(store.bestScore == 50)
        #expect(store.bestScoreSnapshot?.score == 50)
        #expect(store.bestScoreSnapshot?.cps == 5.0)
        #expect(store.bestScoreSnapshot?.playedAt == playedAt)
    }

    @Test("T-020: updateIfNeeded returns false and keeps value when score is lower")
    func updateIfNeeded_lowerScore_keepsExistingValue() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 42

        let didUpdate = store.updateIfNeeded(score: 41, cps: 4.1, playedAt: Date())

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
        _ = store.updateIfNeeded(score: 100, cps: 10.0, playedAt: .now)
        store.updateTodayIfNeeded(score: 80)

        store.resetAll()

        #expect(store.bestScore == 0)
        #expect(store.todayBestScore == 0)
        #expect(store.bestScoreSnapshot == nil)
    }

    @Test("resetAll allows subsequent updates")
    func resetAll_allowsSubsequentUpdates() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 100
        store.updateTodayIfNeeded(score: 80)

        store.resetAll()

        let didUpdateBest = store.updateIfNeeded(score: 30, cps: 3.0, playedAt: .now)
        let didUpdateToday = store.updateTodayIfNeeded(score: 20)

        #expect(didUpdateBest)
        #expect(store.bestScore == 30)
        #expect(didUpdateToday)
        #expect(store.todayBestScore == 20)
    }

    @Test("V3-086: bestScoreSnapshot persists and reloads")
    func bestScoreSnapshot_persistsAndReloads() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let playedAt = Date(timeIntervalSince1970: 2_000)
        let writer = ScoreStore(defaults: defaults)
        _ = writer.updateIfNeeded(score: 240, cps: 24.0, playedAt: playedAt)

        let reader = ScoreStore(defaults: defaults)
        let snapshot = reader.bestScoreSnapshot

        #expect(snapshot?.score == 240)
        #expect(snapshot?.cps == 24.0)
        #expect(snapshot?.playedAt == playedAt)
    }

    @Test("V3-086: bestScoreSnapshot migrates legacy best score")
    func bestScoreSnapshot_migratesLegacyBestScore() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.bestScore = 150

        let snapshot = store.bestScoreSnapshot

        #expect(snapshot?.score == 150)
        #expect(snapshot?.cps == 15.0)
        #expect(snapshot?.playedAt == nil)
    }

    @Test("V3-102: player name is nil by default")
    func playerName_defaultsToNil() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)

        #expect(store.playerName == nil)
    }

    @Test("V3-102: player name saves and loads")
    func playerName_savesAndLoads() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let writer = ScoreStore(defaults: defaults)
        writer.savePlayerName("Hiro")

        let reader = ScoreStore(defaults: defaults)
        #expect(reader.playerName == "Hiro")
    }

    @Test("V3-102: player name sanitization trims and removes disallowed characters")
    func playerName_sanitizesInput() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.savePlayerName("  Hi\u{200B}\n\u{202E}  there  😀  ")

        #expect(store.playerName == "Hi there 😀")
    }

    @Test("V3-102: empty sanitized player name becomes nil")
    func playerName_emptyAfterSanitization_becomesNil() {
        let (defaults, suiteName) = testDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = ScoreStore(defaults: defaults)
        store.savePlayerName(" \n\t ")

        #expect(store.playerName == nil)
    }

    private func testDefaults() -> (UserDefaults, String) {
        let suiteName = "TapBurstTests.ScoreStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }
}
