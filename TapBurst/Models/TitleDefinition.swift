import Foundation

struct TitleDefinition {
    let key: String
    let localizedNameKey: String.LocalizationValue
    let scoreRange: ClosedRange<Int>

    private init(key: String, scoreRange: ClosedRange<Int>) {
        self.key = key
        self.localizedNameKey = String.LocalizationValue(key)
        self.scoreRange = scoreRange
    }

    static let allTitles: [TitleDefinition] = [
        TitleDefinition(key: "title.first_steps", scoreRange: 0...59),
        TitleDefinition(key: "title.getting_there", scoreRange: 60...99),
        TitleDefinition(key: "title.speed_star", scoreRange: 100...134),
        TitleDefinition(key: "title.rush_mode", scoreRange: 135...159),
        TitleDefinition(key: "title.machine_gun", scoreRange: 160...184),
        TitleDefinition(key: "title.burst_master", scoreRange: 185...209),
        TitleDefinition(key: "title.sonic", scoreRange: 210...249),
        TitleDefinition(key: "title.overdrive", scoreRange: 250...299),
        TitleDefinition(key: "title.limit_breaker", scoreRange: 300...349),
        TitleDefinition(key: "title.god_tier", scoreRange: 350...Int.max),
    ]

    var localizedName: String {
        String(localized: localizedNameKey)
    }

    static func title(for score: Int) -> TitleDefinition {
        allTitles.first { $0.scoreRange.contains(score) } ?? allTitles[0]
    }
}
