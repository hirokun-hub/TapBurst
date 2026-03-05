import Foundation

struct TitleDefinition {
    let localizedNameKey: String.LocalizationValue
    let scoreRange: ClosedRange<Int>

    static let allTitles: [TitleDefinition] = [
        TitleDefinition(localizedNameKey: "title.warming_up", scoreRange: 0...49),
        TitleDefinition(localizedNameKey: "title.not_bad", scoreRange: 50...99),
        TitleDefinition(localizedNameKey: "title.speed_star", scoreRange: 100...199),
        TitleDefinition(localizedNameKey: "title.machine_gun", scoreRange: 200...299),
        TitleDefinition(localizedNameKey: "title.sonic", scoreRange: 300...399),
        TitleDefinition(localizedNameKey: "title.beyond_human", scoreRange: 400...499),
        TitleDefinition(localizedNameKey: "title.god_tier", scoreRange: 500...Int.max),
    ]

    var localizedName: String {
        String(localized: localizedNameKey)
    }

    static func title(for score: Int) -> TitleDefinition {
        allTitles.first { $0.scoreRange.contains(score) } ?? allTitles[0]
    }
}
