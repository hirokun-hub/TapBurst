import CoreGraphics
import Foundation

struct ParticleConfig {
    let birthRate: Float
    let scale: CGFloat
    let scaleRange: CGFloat
    let velocity: CGFloat
    let velocityRange: CGFloat
    let lifetime: Float
    let scaleSpeed: CGFloat
    let color: CGColor

    static let normal = ParticleConfig(
        birthRate: 30,
        scale: 0.5,
        scaleRange: 0.2,
        velocity: 120,
        velocityRange: 40,
        lifetime: 0.3,
        scaleSpeed: -0.5,
        color: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
    )
    static let medium = ParticleConfig(
        birthRate: 45,
        scale: 0.75,
        scaleRange: 0.35,
        velocity: 250,
        velocityRange: 80,
        lifetime: 0.45,
        scaleSpeed: -0.8,
        color: CGColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 0.95)
    )
    static let maximum = ParticleConfig(
        birthRate: 60,
        scale: 1.0,
        scaleRange: 0.5,
        velocity: 500,
        velocityRange: 200,
        lifetime: 0.55,
        scaleSpeed: -1.0,
        color: CGColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.95)
    )

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
