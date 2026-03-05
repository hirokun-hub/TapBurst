import Foundation

enum TimeStage: CaseIterable {
    case calm
    case warm
    case intense

    private static let warmThreshold: TimeInterval = 5.0
    private static let intenseThreshold: TimeInterval = 8.0

    static func stage(at elapsed: TimeInterval) -> TimeStage {
        switch elapsed {
        case ..<warmThreshold:
            return .calm
        case ..<intenseThreshold:
            return .warm
        default:
            return .intense
        }
    }
}
