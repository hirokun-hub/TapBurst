import Foundation

enum CPSTier: Int, CaseIterable, Comparable {
    case t0 = 0
    case t1 = 1
    case t2 = 2
    case t3 = 3
    case t4 = 4
    case t5 = 5
    case t6 = 6
    case t7 = 7

    static func tier(for cps: Int) -> CPSTier {
        switch cps {
        case ..<5:
            return .t0
        case ..<8:
            return .t1
        case ..<11:
            return .t2
        case ..<15:
            return .t3
        case ..<19:
            return .t4
        case ..<23:
            return .t5
        case ..<27:
            return .t6
        default:
            return .t7
        }
    }

    static func < (lhs: CPSTier, rhs: CPSTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
