import SwiftUI

struct BackgroundEffectView: View {
    let timeStage: TimeStage
    var cpsTier: CPSTier = .t0

    private static let transitionDuration: TimeInterval = 0.4
    private static let overlayTransitionDuration: TimeInterval = 0.2

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: timeStage),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: overlayColors(for: timeStage),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(overlayOpacity(for: cpsTier))

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
        .animation(.easeInOut(duration: Self.overlayTransitionDuration), value: cpsTier)
    }

    private func gradientColors(for stage: TimeStage) -> [Color] {
        switch stage {
        case .calm:
            return [Color(red: 0.04, green: 0.09, blue: 0.29), Color(red: 0.00, green: 0.20, blue: 0.45)]
        case .warm:
            return [Color(red: 0.37, green: 0.12, blue: 0.54), Color(red: 0.95, green: 0.48, blue: 0.17)]
        case .intense:
            return [Color(red: 0.83, green: 0.11, blue: 0.13), Color(red: 0.85, green: 0.70, blue: 0.12)]
        }
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

    private func overlayColors(for stage: TimeStage) -> [Color] {
        switch stage {
        case .calm:
            return [
                Color(red: 0.72, green: 0.84, blue: 0.85),
                Color(red: 0.45, green: 0.68, blue: 0.84)
            ]
        case .warm:
            return [
                Color(red: 0.67, green: 0.42, blue: 0.80),
                Color(red: 0.49, green: 0.30, blue: 0.71)
            ]
        case .intense:
            return [
                Color(red: 0.85, green: 0.42, blue: 0.20),
                Color(red: 0.78, green: 0.18, blue: 0.16)
            ]
        }
    }

    private func overlayOpacity(for tier: CPSTier) -> Double {
        switch tier {
        case .t0:
            return 0.0
        case .t1:
            return 0.05
        case .t2:
            return 0.10
        case .t3:
            return 0.15
        case .t4:
            return 0.20
        case .t5:
            return 0.25
        case .t6:
            return 0.30
        case .t7:
            return 0.35
        }
    }
}

#Preview(traits: .landscapeLeft) {
    BackgroundEffectView(timeStage: .warm, cpsTier: .t4)
}
