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

    static let t0 = ParticleConfig(
        birthRate: 30,
        scale: 0.5,
        scaleRange: 0.2,
        velocity: 120,
        velocityRange: 40,
        lifetime: 0.3,
        scaleSpeed: -0.5,
        color: CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
    )
    static let t1 = ParticleConfig(
        birthRate: 34,
        scale: 0.58,
        scaleRange: 0.22,
        velocity: 160,
        velocityRange: 50,
        lifetime: 0.32,
        scaleSpeed: -0.55,
        color: CGColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 0.95)
    )
    static let t2 = ParticleConfig(
        birthRate: 38,
        scale: 0.66,
        scaleRange: 0.26,
        velocity: 210,
        velocityRange: 60,
        lifetime: 0.36,
        scaleSpeed: -0.65,
        color: CGColor(red: 1.0, green: 0.88, blue: 0.62, alpha: 0.95)
    )
    static let t3 = ParticleConfig(
        birthRate: 44,
        scale: 0.74,
        scaleRange: 0.30,
        velocity: 270,
        velocityRange: 75,
        lifetime: 0.40,
        scaleSpeed: -0.75,
        color: CGColor(red: 1.0, green: 0.82, blue: 0.44, alpha: 0.95)
    )
    static let t4 = ParticleConfig(
        birthRate: 50,
        scale: 0.82,
        scaleRange: 0.36,
        velocity: 340,
        velocityRange: 100,
        lifetime: 0.45,
        scaleSpeed: -0.85,
        color: CGColor(red: 1.0, green: 0.78, blue: 0.3, alpha: 0.95)
    )
    static let t5 = ParticleConfig(
        birthRate: 56,
        scale: 0.90,
        scaleRange: 0.42,
        velocity: 410,
        velocityRange: 130,
        lifetime: 0.50,
        scaleSpeed: -0.95,
        color: CGColor(red: 1.0, green: 0.72, blue: 0.2, alpha: 0.95)
    )
    static let t6 = ParticleConfig(
        birthRate: 60,
        scale: 0.98,
        scaleRange: 0.46,
        velocity: 470,
        velocityRange: 165,
        lifetime: 0.53,
        scaleSpeed: -1.0,
        color: CGColor(red: 1.0, green: 0.66, blue: 0.16, alpha: 0.95)
    )
    static let t7 = ParticleConfig(
        birthRate: 64,
        scale: 1.06,
        scaleRange: 0.50,
        velocity: 540,
        velocityRange: 200,
        lifetime: 0.56,
        scaleSpeed: -1.05,
        color: CGColor(red: 1.0, green: 0.6, blue: 0.12, alpha: 0.95)
    )

    static func config(for tier: CPSTier) -> ParticleConfig {
        switch tier {
        case .t0:
            return .t0
        case .t1:
            return .t1
        case .t2:
            return .t2
        case .t3:
            return .t3
        case .t4:
            return .t4
        case .t5:
            return .t5
        case .t6:
            return .t6
        case .t7:
            return .t7
        }
    }
}
