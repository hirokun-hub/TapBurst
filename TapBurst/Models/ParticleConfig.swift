import CoreGraphics
import Foundation

struct ParticleConfig {
    let birthRate: Float
    let scale: CGFloat
    let lifetime: Float

    static let normal = ParticleConfig(birthRate: 30, scale: 0.5, lifetime: 0.3)
    static let medium = ParticleConfig(birthRate: 48, scale: 0.75, lifetime: 0.4)
    static let maximum = ParticleConfig(birthRate: 64, scale: 1.0, lifetime: 0.5)

    static func config(for tier: CPSTier) -> ParticleConfig {
        switch tier {
        case .normal:
            return .normal
        case .medium:
            return .medium
        case .maximum:
            return .maximum
        }
    }
}
