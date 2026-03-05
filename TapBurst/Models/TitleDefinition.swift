import Foundation

struct TitleDefinition {
    let localizedNameKey: String.LocalizationValue
    let scoreRange: ClosedRange<Int>

    static let allTitles: [TitleDefinition] = [
        TitleDefinition(localizedNameKey: "title.warming_up", scoreRange: 0...49),
        TitleDefinition(localizedNameKey: "title.not_bad", scoreRange: 50...99),
        TitleDefinition(localizedNameKey: "title.speed_star", scoreRange: 100...159),
        TitleDefinition(localizedNameKey: "title.machine_gun", scoreRange: 160...219),
        TitleDefinition(localizedNameKey: "title.sonic", scoreRange: 220...289),
        TitleDefinition(localizedNameKey: "title.beyond_human", scoreRange: 290...369),
        TitleDefinition(localizedNameKey: "title.god_tier", scoreRange: 370...Int.max),
    ]

    var localizedName: String {
        String(localized: localizedNameKey)
    }

    static func title(for score: Int) -> TitleDefinition {
        allTitles.first { $0.scoreRange.contains(score) } ?? allTitles[0]
    }
}
