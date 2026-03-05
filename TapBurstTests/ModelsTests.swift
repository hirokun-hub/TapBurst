import Testing
import CoreFoundation
@testable import TapBurst

struct ModelsTests {

    @Test("T-010: GamePhase has 4 cases")
    func gamePhase_hasFourCases() {
        #expect(GamePhase.allCases.count == 4)
        #expect(GamePhase.allCases.contains(.home))
        #expect(GamePhase.allCases.contains(.countdown))
        #expect(GamePhase.allCases.contains(.playing))
        #expect(GamePhase.allCases.contains(.results))
    }

    @Test("T-011: TitleDefinition boundary mapping")
    func titleDefinition_boundaryValues() {
        let boundaryScores = [0, 49, 50, 99, 100, 199, 200, 299, 300, 399, 400, 499, 500, 999]

        for score in boundaryScores {
            let title = TitleDefinition.title(for: score)
            #expect(title.scoreRange.contains(score))
            #expect(!title.localizedName.isEmpty)
        }
    }

    @Test("T-011: TitleDefinition covers all scores without gaps")
    func titleDefinition_hasNoRangeGaps() {
        #expect(!TitleDefinition.allTitles.isEmpty)

        let sortedRanges = TitleDefinition.allTitles
            .map(\.scoreRange)
            .sorted { $0.lowerBound < $1.lowerBound }

        #expect(sortedRanges.first?.lowerBound == 0)
        #expect(sortedRanges.last?.upperBound == Int.max)

        for index in 0..<(sortedRanges.count - 1) {
            let current = sortedRanges[index]
            let next = sortedRanges[index + 1]
            #expect(current.upperBound + 1 == next.lowerBound)
        }

        let sampleScores = [0, 25, 49, 50, 75, 99, 100, 150, 199, 200, 250, 299, 300, 350, 399, 400, 450, 499, 500, 999, 10_000]
        for score in sampleScores {
            let hitCount = TitleDefinition.allTitles.filter { $0.scoreRange.contains(score) }.count
            #expect(hitCount == 1)
        }
    }

    @Test("T-012: TimeStage boundary mapping")
    func timeStage_boundaryValues() {
        #expect(TimeStage.stage(at: 0) == .calm)
        #expect(TimeStage.stage(at: 4.99) == .calm)
        #expect(TimeStage.stage(at: 5.0) == .warm)
        #expect(TimeStage.stage(at: 7.99) == .warm)
        #expect(TimeStage.stage(at: 8.0) == .intense)
        #expect(TimeStage.stage(at: 10.0) == .intense)
    }

    @Test("T-013: CPSTier boundary mapping")
    func cpsTier_boundaryValues() {
        #expect(CPSTier.tier(for: 0) == .normal)
        #expect(CPSTier.tier(for: 4) == .normal)
        #expect(CPSTier.tier(for: 5) == .medium)
        #expect(CPSTier.tier(for: 14) == .medium)
        #expect(CPSTier.tier(for: 15) == .maximum)
        #expect(CPSTier.tier(for: 100) == .maximum)
    }

    @Test("T-014: ParticleConfig values and mapping")
    func particleConfig_values() {
        #expect(ParticleConfig.normal.birthRate == 30)
        #expect(ParticleConfig.normal.scale == 0.5)
        #expect(ParticleConfig.normal.lifetime == 0.3)

        #expect(ParticleConfig.medium.birthRate == 48)
        #expect(ParticleConfig.medium.scale == 0.75)
        #expect(ParticleConfig.medium.lifetime == 0.4)

        #expect(ParticleConfig.maximum.birthRate == 64)
        #expect(ParticleConfig.maximum.scale == 1.0)
        #expect(ParticleConfig.maximum.lifetime == 0.5)

        #expect(ParticleConfig.config(for: .normal).birthRate == ParticleConfig.normal.birthRate)
        #expect(ParticleConfig.config(for: .medium).birthRate == ParticleConfig.medium.birthRate)
        #expect(ParticleConfig.config(for: .maximum).birthRate == ParticleConfig.maximum.birthRate)
    }

    @Test("T-015: PitchConfig values and mapping")
    func pitchConfig_values() {
        #expect(PitchConfig.normal.pitchShift == 0)
        #expect(PitchConfig.medium.pitchShift == 200)
        #expect(PitchConfig.maximum.pitchShift == 500)

        #expect(PitchConfig.config(for: .normal).pitchShift == PitchConfig.normal.pitchShift)
        #expect(PitchConfig.config(for: .medium).pitchShift == PitchConfig.medium.pitchShift)
        #expect(PitchConfig.config(for: .maximum).pitchShift == PitchConfig.maximum.pitchShift)
    }
}
