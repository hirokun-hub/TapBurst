import SwiftUI

struct BackgroundEffectView: View {
    let timeStage: TimeStage

    private static let transitionDuration: TimeInterval = 0.4

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors(for: timeStage),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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

    private func gradientColors(for stage: TimeStage) -> [Color] {
        switch stage {
        case .calm:
            return [Color(red: 0.04, green: 0.09, blue: 0.29), Color(red: 0.00, green: 0.20, blue: 0.45)]
        case .warm:
            return [Color(red: 0.37, green: 0.12, blue: 0.54), Color(red: 0.95, green: 0.48, blue: 0.17)]
        case .intense:
            return [Color(red: 0.83, green: 0.11, blue: 0.13), Color(red: 0.99, green: 0.82, blue: 0.14)]
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
}

#Preview(traits: .landscapeLeft) {
    BackgroundEffectView(timeStage: .warm)
}
