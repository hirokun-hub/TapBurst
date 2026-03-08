import Testing
import CoreFoundation
import CoreGraphics
import Foundation
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
        let expectations: [(score: Int, expectedKey: String)] = [
            (0, "title.first_steps"),
            (59, "title.first_steps"),
            (60, "title.getting_there"),
            (99, "title.getting_there"),
            (100, "title.speed_star"),
            (134, "title.speed_star"),
            (135, "title.rush_mode"),
            (159, "title.rush_mode"),
            (160, "title.machine_gun"),
            (184, "title.machine_gun"),
            (185, "title.burst_master"),
            (209, "title.burst_master"),
            (210, "title.sonic"),
            (249, "title.sonic"),
            (250, "title.overdrive"),
            (299, "title.overdrive"),
            (300, "title.limit_breaker"),
            (349, "title.limit_breaker"),
            (350, "title.god_tier"),
            (600, "title.god_tier"),
        ]

        for (score, expectedKey) in expectations {
            let title = TitleDefinition.title(for: score)
            #expect(title.scoreRange.contains(score))
            #expect(title.key == expectedKey)
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

        let sampleScores = [0, 30, 59, 60, 80, 99, 100, 120, 134, 135, 150, 159, 160, 175, 184, 185, 200, 209, 210, 230, 249, 250, 280, 299, 300, 330, 349, 350, 600, 10_000]
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

    @Test("V3-020: CPSTier boundary mapping")
    func cpsTier_boundaryValues() {
        #expect(CPSTier.tier(for: -1) == .t0)
        #expect(CPSTier.tier(for: 0) == .t0)
        #expect(CPSTier.tier(for: 4) == .t0)
        #expect(CPSTier.tier(for: 5) == .t1)
        #expect(CPSTier.tier(for: 7) == .t1)
        #expect(CPSTier.tier(for: 8) == .t2)
        #expect(CPSTier.tier(for: 10) == .t2)
        #expect(CPSTier.tier(for: 11) == .t3)
        #expect(CPSTier.tier(for: 14) == .t3)
        #expect(CPSTier.tier(for: 15) == .t4)
        #expect(CPSTier.tier(for: 18) == .t4)
        #expect(CPSTier.tier(for: 19) == .t5)
        #expect(CPSTier.tier(for: 22) == .t5)
        #expect(CPSTier.tier(for: 23) == .t6)
        #expect(CPSTier.tier(for: 26) == .t6)
        #expect(CPSTier.tier(for: 27) == .t7)
        #expect(CPSTier.tier(for: 100) == .t7)
        #expect(CPSTier.t0 < .t1)
        #expect(CPSTier.t6 < .t7)
    }

    @Test("V3-040: ParticleConfig values, limits, and mapping")
    func particleConfig_values() {
        let expectedConfigs: [(tier: CPSTier, config: ParticleConfig, color: [CGFloat])] = [
            (.t0, .t0, [1.0, 1.0, 1.0, 0.95]),
            (.t1, .t1, [1.0, 0.95, 0.8, 0.95]),
            (.t2, .t2, [1.0, 0.88, 0.62, 0.95]),
            (.t3, .t3, [1.0, 0.82, 0.44, 0.95]),
            (.t4, .t4, [1.0, 0.78, 0.3, 0.95]),
            (.t5, .t5, [1.0, 0.72, 0.2, 0.95]),
            (.t6, .t6, [1.0, 0.66, 0.16, 0.95]),
            (.t7, .t7, [1.0, 0.6, 0.12, 0.95]),
        ]

        let expectedBirthRates: [Float] = [30, 34, 38, 44, 50, 56, 60, 64]
        let expectedScales: [CGFloat] = [0.50, 0.58, 0.66, 0.74, 0.82, 0.90, 0.98, 1.06]
        let expectedLifetimes: [Float] = [0.30, 0.32, 0.36, 0.40, 0.45, 0.50, 0.53, 0.56]
        let expectedVelocities: [CGFloat] = [120, 160, 210, 270, 340, 410, 470, 540]

        for (index, expected) in expectedConfigs.enumerated() {
            let config = ParticleConfig.config(for: expected.tier)
            #expect(config.birthRate == expectedBirthRates[index])
            #expect(config.scale == expectedScales[index])
            #expect(config.lifetime == expectedLifetimes[index])
            #expect(config.velocity == expectedVelocities[index])
            #expect(config.birthRate <= 64)
            #expect(colorComponents(config.color) == expected.color)

            if index > 0 {
                let previous = ParticleConfig.config(for: expectedConfigs[index - 1].tier)
                #expect(previous.birthRate < config.birthRate)
                #expect(previous.scale < config.scale)
            }
        }
    }

    @Test("V3-030: PitchConfig values and mapping")
    func pitchConfig_values() {
        let expectedPitchShifts: [(CPSTier, Float)] = [
            (.t0, 0),
            (.t1, 60),
            (.t2, 130),
            (.t3, 220),
            (.t4, 320),
            (.t5, 430),
            (.t6, 540),
            (.t7, 680),
        ]

        for (tier, expectedPitchShift) in expectedPitchShifts {
            #expect(PitchConfig.config(for: tier).pitchShift == expectedPitchShift)
        }
    }

    @Test("V3-BG: CPSTier.baseHSB t0 returns deep indigo")
    func cpsTier_baseHSB_t0() {
        let hsb = CPSTier.t0.baseHSB
        #expect(hsb.h == 0.64)
        #expect(hsb.s == 0.55)
        #expect(hsb.b == 0.26)
    }

    @Test("V3-BG: CPSTier.baseHSB t7 returns orange-red")
    func cpsTier_baseHSB_t7() {
        let hsb = CPSTier.t7.baseHSB
        #expect(hsb.h == 0.08)
        #expect(hsb.s == 0.90)
        #expect(hsb.b == 0.73)
    }

    // MARK: - CPSTierFilter hysteresis tests

    @Test("V3-BG: CPSTierFilter ignores change before upDelay")
    func tierFilter_upDelay_notElapsed() {
        var filter = CPSTierFilter()
        // First call sets pending
        let changed1 = filter.update(rawTier: .t1, now: 1.0)
        #expect(!changed1)
        #expect(filter.confirmedTier == .t0)

        // Before 150ms - should not confirm
        let changed2 = filter.update(rawTier: .t1, now: 1.14)
        #expect(!changed2)
        #expect(filter.confirmedTier == .t0)
    }

    @Test("V3-BG: CPSTierFilter confirms upgrade after upDelay")
    func tierFilter_upDelay_elapsed() {
        var filter = CPSTierFilter()
        _ = filter.update(rawTier: .t1, now: 1.0)

        // Past 150ms - should confirm
        let changed = filter.update(rawTier: .t1, now: 1.16)
        #expect(changed)
        #expect(filter.confirmedTier == .t1)
    }

    @Test("V3-BG: CPSTierFilter uses longer delay for downgrade")
    func tierFilter_downDelay() {
        var filter = CPSTierFilter()
        // Start at t3
        _ = filter.update(rawTier: .t3, now: 0.0)
        _ = filter.update(rawTier: .t3, now: 0.15)
        #expect(filter.confirmedTier == .t3)

        // Request downgrade to t1
        _ = filter.update(rawTier: .t1, now: 1.0)

        // Before 300ms - should not confirm
        let changed1 = filter.update(rawTier: .t1, now: 1.29)
        #expect(!changed1)
        #expect(filter.confirmedTier == .t3)

        // At 300ms - should confirm
        let changed2 = filter.update(rawTier: .t1, now: 1.30)
        #expect(changed2)
        #expect(filter.confirmedTier == .t1)
    }

    @Test("V3-BG: CPSTierFilter resets pending when rawTier returns to confirmed")
    func tierFilter_pendingReset() {
        var filter = CPSTierFilter()
        // Set pending to t1
        _ = filter.update(rawTier: .t1, now: 1.0)
        #expect(filter.confirmedTier == .t0)

        // Return to t0 - pending should reset
        let changed = filter.update(rawTier: .t0, now: 1.05)
        #expect(!changed)
        #expect(filter.confirmedTier == .t0)

        // New pending to t1 requires full delay from scratch
        _ = filter.update(rawTier: .t1, now: 1.10)
        let changed2 = filter.update(rawTier: .t1, now: 1.20)
        #expect(!changed2) // only 100ms since new pending, not 150ms
    }

    @Test("V3-BG: CPSTierFilter resets pending when rawTier changes to different tier")
    func tierFilter_pendingChangesToDifferentTier() {
        var filter = CPSTierFilter()
        _ = filter.update(rawTier: .t1, now: 1.0)

        // Change to t2 instead - should reset pending timer
        _ = filter.update(rawTier: .t2, now: 1.1)

        // 150ms from original t1 pending, but only 50ms from t2 pending
        let changed = filter.update(rawTier: .t2, now: 1.15)
        #expect(!changed)

        // Past 150ms from t2 pending
        let changed2 = filter.update(rawTier: .t2, now: 1.26)
        #expect(changed2)
        #expect(filter.confirmedTier == .t2)
    }

    @Test("V3-BG: CPSTierFilter reset clears state")
    func tierFilter_reset() {
        var filter = CPSTierFilter()
        _ = filter.update(rawTier: .t3, now: 0.0)
        _ = filter.update(rawTier: .t3, now: 0.15)
        #expect(filter.confirmedTier == .t3)

        filter.reset()
        #expect(filter.confirmedTier == .t0)
    }

    @Test("V3-085: ScoreResult stores cps value")
    func scoreResult_storesCpsValue() {
        let result = ScoreResult(
            score: 188,
            cps: 18.8,
            title: TitleDefinition.title(for: 188),
            isNewBest: true,
            playedAt: .now
        )

        #expect(result.cps == 18.8)
    }

    private func colorComponents(_ color: CGColor) -> [CGFloat] {
        color.components ?? []
    }
}
