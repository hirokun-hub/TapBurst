import Testing
import CoreFoundation
import CoreGraphics
@testable import TapBurst

struct ModelsTests {

    @Test("V2-010: GamePhase has 5 cases")
    func gamePhase_hasFiveCases() {
        #expect(GamePhase.allCases.count == 5)
        #expect(GamePhase.allCases.contains(.home))
        #expect(GamePhase.allCases.contains(.countdown))
        #expect(GamePhase.allCases.contains(.playing))
        #expect(GamePhase.allCases.contains(.finish))
        #expect(GamePhase.allCases.contains(.results))
    }

    @Test("V2-013: TitleDefinition boundary mapping")
    func titleDefinition_boundaryValues() {
        let boundaryScores = [0, 49, 50, 99, 100, 159, 160, 219, 220, 289, 290, 369, 370, 600]

        for score in boundaryScores {
            let title = TitleDefinition.title(for: score)
            #expect(title.scoreRange.contains(score))
            #expect(!title.localizedName.isEmpty)
        }
    }

    @Test("V2-013: TitleDefinition covers all scores without gaps")
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

        let sampleScores = [0, 25, 49, 50, 75, 99, 100, 130, 159, 160, 190, 219, 220, 250, 289, 290, 330, 369, 370, 600, 10_000]
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

    @Test("V2-014: CPSTier boundary mapping")
    func cpsTier_boundaryValues() {
        #expect(CPSTier.tier(for: 0) == .normal)
        #expect(CPSTier.tier(for: 7) == .normal)
        #expect(CPSTier.tier(for: 8) == .medium)
        #expect(CPSTier.tier(for: 19) == .medium)
        #expect(CPSTier.tier(for: 20) == .maximum)
        #expect(CPSTier.tier(for: 60) == .maximum)
    }

    @Test("V2-015: ParticleConfig values and mapping")
    func particleConfig_values() {
        #expect(ParticleConfig.normal.birthRate == 30)
        #expect(ParticleConfig.normal.scale == 0.5)
        #expect(ParticleConfig.normal.scaleRange == 0.2)
        #expect(ParticleConfig.normal.velocity == 120)
        #expect(ParticleConfig.normal.velocityRange == 40)
        #expect(ParticleConfig.normal.lifetime == 0.3)
        #expect(ParticleConfig.normal.scaleSpeed == -0.5)
        #expect(colorComponents(ParticleConfig.normal.color) == [1.0, 1.0, 1.0, 0.95])

        #expect(ParticleConfig.medium.birthRate == 45)
        #expect(ParticleConfig.medium.scale == 0.75)
        #expect(ParticleConfig.medium.scaleRange == 0.35)
        #expect(ParticleConfig.medium.velocity == 250)
        #expect(ParticleConfig.medium.velocityRange == 80)
        #expect(ParticleConfig.medium.lifetime == 0.45)
        #expect(ParticleConfig.medium.scaleSpeed == -0.8)
        #expect(colorComponents(ParticleConfig.medium.color) == [1.0, 0.7, 0.2, 0.95])

        #expect(ParticleConfig.maximum.birthRate == 60)
        #expect(ParticleConfig.maximum.scale == 1.0)
        #expect(ParticleConfig.maximum.scaleRange == 0.5)
        #expect(ParticleConfig.maximum.velocity == 500)
        #expect(ParticleConfig.maximum.velocityRange == 200)
        #expect(ParticleConfig.maximum.lifetime == 0.55)
        #expect(ParticleConfig.maximum.scaleSpeed == -1.0)
        #expect(colorComponents(ParticleConfig.maximum.color) == [1.0, 0.8, 0.2, 0.95])

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

    private func colorComponents(_ color: CGColor) -> [CGFloat] {
        color.components ?? []
    }
}
