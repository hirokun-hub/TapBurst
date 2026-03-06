import SwiftUI

struct GamePlayView: View {
    @Bindable var gameManager: GameManager

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: gameManager.currentTimeStage)
                .allowsHitTesting(false)

            GameTouchView(
                phase: gameManager.phase,
                particleTier: gameManager.currentCPSTier
            ) { _ in
                gameManager.registerTap()
            }

            FlashOverlayView(opacity: gameManager.flashOpacity)
                .allowsHitTesting(false)

            GameHUDView(
                score: gameManager.session?.score ?? 0,
                remainingTime: gameManager.remainingTime
            )
            .allowsHitTesting(false)
        }
        .offset(gameManager.shakeOffset)
        .statusBarHidden(true)
    }
}

#Preview(traits: .landscapeLeft) {
    GamePlayView(gameManager: GameManager())
}
