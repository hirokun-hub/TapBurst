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
        case .t0: return (h: 0.640, s: 0.550, b: 0.260)
        case .t1: return (h: 0.772, s: 0.682, b: 0.393)
        case .t2: return (h: 0.842, s: 0.737, b: 0.468)
        case .t3: return (h: 0.900, s: 0.779, b: 0.531)
        case .t4: return (h: 0.951, s: 0.815, b: 0.587)
        case .t5: return (h: 0.997, s: 0.846, b: 0.638)
        case .t6: return (h: 0.040, s: 0.874, b: 0.685)
        case .t7: return (h: 0.080, s: 0.900, b: 0.730)
        }
    }

    static func < (lhs: CPSTier, rhs: CPSTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
