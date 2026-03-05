import Foundation

enum CPSTier: CaseIterable {
    case normal
    case medium
    case maximum

    private static let mediumThreshold = 8
    private static let maximumThreshold = 20

    static func tier(for cps: Int) -> CPSTier {
        switch cps {
        case ..<mediumThreshold:
            return .normal
        case ..<maximumThreshold:
            return .medium
        default:
            return .maximum
        }
    }
}
