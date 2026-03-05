import Foundation

struct GameSession {
    var score: Int = 0
    var tapTimestamps: [TimeInterval] = []
    var lastValidTapTime: TimeInterval = 0
    let startTime: TimeInterval
}
