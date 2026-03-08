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

    static func interpolatedPitchShift(for cps: Int) -> Float {
        let keypoints: [(cps: Float, pitch: Float)] = [
            (0, 0), (5, 150), (8, 280), (11, 400),
            (15, 520), (19, 630), (23, 700), (27, 750),
        ]

        let cpsF = Float(cps)

        if cpsF <= keypoints.first!.cps {
            return keypoints.first!.pitch
        }
        if cpsF >= keypoints.last!.cps {
            return keypoints.last!.pitch
        }

        for i in 0..<(keypoints.count - 1) {
            let lo = keypoints[i]
            let hi = keypoints[i + 1]
            if cpsF >= lo.cps && cpsF < hi.cps {
                let t = (cpsF - lo.cps) / (hi.cps - lo.cps)
                return lo.pitch + t * (hi.pitch - lo.pitch)
            }
        }

        return keypoints.last!.pitch
    }
}
