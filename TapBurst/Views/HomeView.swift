import SwiftUI

struct HomeView: View {
    @Bindable var gameManager: GameManager

    private static let spacing: CGFloat = 28

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .calm)

            VStack(spacing: Self.spacing) {
                Text("TapBurst")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text(String(localized: "home.best_score"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("\(gameManager.bestScore)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(String(localized: "home.best_score")))
                .accessibilityValue(Text("\(gameManager.bestScore)"))
                .accessibilityAddTraits(.isStaticText)
                .accessibilitySortPriority(2)

                Button {
                    gameManager.startGame()
                } label: {
                    Text(String(localized: "home.start"))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 360)
                        .padding(.vertical, 18)
                        .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(String(localized: "home.start")))
                .accessibilityHint(Text(String(localized: "a11y.home.start_hint")))
                .accessibilitySortPriority(1)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView(gameManager: GameManager())
}
