import SwiftUI

struct CountdownView: View {
    @Bindable var gameManager: GameManager

    private static let countdownFontSize: CGFloat = 130
    private static let invalidMessageFontSize: CGFloat = 36

    private var countdownText: String {
        if let number = gameManager.countdownNumber {
            return String(number)
        }
        return "GO!"
    }

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .calm)

            Text(countdownText)
                .font(.system(size: Self.countdownFontSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            if gameManager.invalidTapOverlayOpacity > 0 {
                Color.red
                    .opacity(gameManager.invalidTapOverlayOpacity)
                    .overlay {
                        Text(String(localized: "game.tap_invalid"))
                            .font(.system(size: Self.invalidMessageFontSize, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            gameManager.registerInvalidCountdownTap()
        }
        .offset(gameManager.shakeOffset)
    }
}

#Preview {
    CountdownView(gameManager: GameManager())
}
