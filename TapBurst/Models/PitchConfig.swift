import Foundation

struct PitchConfig {
    let pitchShift: Float

    static func config(for tier: CPSTier) -> PitchConfig {
        switch tier {
        case .t0:
            return PitchConfig(pitchShift: 0)
        case .t1:
            return PitchConfig(pitchShift: 150)
        case .t2:
            return PitchConfig(pitchShift: 280)
        case .t3:
            return PitchConfig(pitchShift: 400)
        case .t4:
            return PitchConfig(pitchShift: 520)
        case .t5:
            return PitchConfig(pitchShift: 630)
        case .t6:
            return PitchConfig(pitchShift: 700)
        case .t7:
            return PitchConfig(pitchShift: 750)
        }
    }
}
