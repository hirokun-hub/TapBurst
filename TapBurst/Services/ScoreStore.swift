import Foundation

struct BestScoreSnapshot: Codable {
    let score: Int
    let cps: Double
    let playedAt: Date?
}

final class ScoreStore {
    private static let bestScoreKey = "bestScore"
    private static let bestScoreSnapshotKey = "bestScoreSnapshot"
    private static let todayBestScoreKey = "todayBestScore"
    private static let todayBestDateKey = "todayBestDate"
    private static let playerNameKey = "playerName"

    private let defaults: UserDefaults
    private let dateProvider: () -> Date
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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

    var bestScoreSnapshot: BestScoreSnapshot? {
        get {
            if let data = defaults.data(forKey: Self.bestScoreSnapshotKey),
               let snapshot = try? decoder.decode(BestScoreSnapshot.self, from: data) {
                return snapshot
            }

            let legacyBestScore = bestScore
            guard legacyBestScore > 0 else {
                return nil
            }

            let migratedSnapshot = BestScoreSnapshot(
                score: legacyBestScore,
                cps: Double(legacyBestScore) / 10.0,
                playedAt: nil
            )
            saveSnapshot(migratedSnapshot)
            return migratedSnapshot
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Self.bestScoreSnapshotKey)
                return
            }
            saveSnapshot(newValue)
        }
    }

    var playerName: String? {
        defaults.string(forKey: Self.playerNameKey)
    }

    @discardableResult
    func updateIfNeeded(score: Int, cps: Double, playedAt: Date) -> Bool {
        guard score > bestScore else {
            return false
        }

        bestScore = score
        bestScoreSnapshot = BestScoreSnapshot(score: score, cps: cps, playedAt: playedAt)
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

    func savePlayerName(_ name: String) {
        guard let sanitizedName = Self.sanitizePlayerName(name) else {
            defaults.removeObject(forKey: Self.playerNameKey)
            return
        }
        defaults.set(sanitizedName, forKey: Self.playerNameKey)
    }

    func resetAll() {
        defaults.removeObject(forKey: Self.bestScoreKey)
        defaults.removeObject(forKey: Self.bestScoreSnapshotKey)
        defaults.removeObject(forKey: Self.todayBestScoreKey)
        defaults.removeObject(forKey: Self.todayBestDateKey)
    }

    private func saveSnapshot(_ snapshot: BestScoreSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        defaults.set(data, forKey: Self.bestScoreSnapshotKey)
    }

    private static func sanitizePlayerName(_ rawValue: String) -> String? {
        let filteredScalars = rawValue.unicodeScalars.filter { scalar in
            !CharacterSet.controlCharacters.contains(scalar) &&
            !disallowedPlayerNameScalars.contains(scalar.value)
        }
        let filtered = String(String.UnicodeScalarView(filteredScalars))
        let collapsedWhitespace = filtered
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let trimmed = collapsedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return String(trimmed.prefix(Self.playerNameCharacterLimit))
    }

    private static let playerNameCharacterLimit = 12
    private static let disallowedPlayerNameScalars: Set<UInt32> = [
        0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF,
        0x202A, 0x202B, 0x202C, 0x202D, 0x202E,
        0x2066, 0x2067, 0x2068, 0x2069
    ]
}
