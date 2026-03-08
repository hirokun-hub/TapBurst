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

    var baseHSB: (h: Double, s: Double, b: Double) {
        switch self {
        case .t0: return (h: 0.64, s: 0.55, b: 0.26)
        case .t1: return (h: 0.62, s: 0.62, b: 0.31)
        case .t2: return (h: 0.60, s: 0.70, b: 0.37)
        case .t3: return (h: 0.73, s: 0.72, b: 0.43)
        case .t4: return (h: 0.83, s: 0.74, b: 0.49)
        case .t5: return (h: 0.94, s: 0.80, b: 0.57)
        case .t6: return (h: 0.03, s: 0.86, b: 0.65)
        case .t7: return (h: 0.08, s: 0.90, b: 0.73)
        }
    }

    static func < (lhs: CPSTier, rhs: CPSTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
