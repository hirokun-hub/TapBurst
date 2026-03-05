import Foundation

struct PitchConfig {
    let pitchShift: Float

    static let normal = PitchConfig(pitchShift: 0)
    static let medium = PitchConfig(pitchShift: 200)
    static let maximum = PitchConfig(pitchShift: 500)

    static func config(for tier: CPSTier) -> PitchConfig {
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
