import Foundation

struct GameSession {
    var score: Int = 0
    var maxSimultaneousTouches: Int = 0
    var tapTimestamps: [TimeInterval] = []
    let startTime: TimeInterval
}
