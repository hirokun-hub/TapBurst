import SwiftUI

struct BackgroundEffectView: View {
    let timeStage: TimeStage
    var cpsTier: CPSTier = .t0

    private static let transitionDuration: TimeInterval = 0.4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: cpsTier),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .id(cpsTier)
            .transition(.opacity)

            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(vignetteOpacity(for: timeStage))
                ],
                center: .center,
                startRadius: 80,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: Self.transitionDuration), value: timeStage)
    }

    private func gradientColors(for tier: CPSTier) -> [Color] {
        let hsb = tier.baseHSB
        let topLeading = Color(
            hue: hsb.h,
            saturation: max(0, hsb.s - 0.06),
            brightness: max(0, hsb.b - 0.08)
        )
        let bottomTrailing = Color(
            hue: fmod(hsb.h - 0.02 + 1, 1),
            saturation: min(1, hsb.s + 0.04),
            brightness: min(0.85, hsb.b + 0.08)
        )
        return [topLeading, bottomTrailing]
    }

    private func vignetteOpacity(for stage: TimeStage) -> Double {
        switch stage {
        case .calm:
            return 0.0
        case .warm:
            return 0.3
        case .intense:
            return 0.5
        }
    }
}

#Preview(traits: .landscapeLeft) {
    BackgroundEffectView(timeStage: .warm, cpsTier: .t4)
}
