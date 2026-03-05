import Foundation

struct ScoreResult {
    let score: Int
    let cps: Double
    let maxSimultaneousTouches: Int
    let title: TitleDefinition
    let isNewBest: Bool
    let playedAt: Date
}
