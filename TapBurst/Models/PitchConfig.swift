import Foundation

struct PitchConfig {
    let pitchShift: Float

    static func config(for tier: CPSTier) -> PitchConfig {
        switch tier {
        case .t0:
            return PitchConfig(pitchShift: 0)
        case .t1:
            return PitchConfig(pitchShift: 60)
        case .t2:
            return PitchConfig(pitchShift: 130)
        case .t3:
            return PitchConfig(pitchShift: 220)
        case .t4:
            return PitchConfig(pitchShift: 320)
        case .t5:
            return PitchConfig(pitchShift: 430)
        case .t6:
            return PitchConfig(pitchShift: 540)
        case .t7:
            return PitchConfig(pitchShift: 680)
        }
    }
}
