import Combine
import SwiftUI

struct FinishView: View {
    let score: Int

    private static let animationDuration: TimeInterval = 0.85
    private static let titleFontSize: CGFloat = 54
    private static let scoreFontSize: CGFloat = 144

    @State private var displayedScore: Int = 0
    @State private var animationStartDate: Date?
    @State private var isAnimating = false

    private let animationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .warm)

            VStack(spacing: 18) {
                Text(String(localized: "finish.title"))
                    .font(.system(size: Self.titleFontSize, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(2)

                Text("\(displayedScore)")
                    .font(.system(size: Self.scoreFontSize, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
        .onAppear {
            startCountUpAnimation()
        }
        .onChange(of: score) { _, _ in
            startCountUpAnimation()
        }
        .onReceive(animationTimer) { currentDate in
            updateDisplayedScore(at: currentDate)
        }
        .onDisappear {
            stopCountUpAnimation()
        }
    }

    private func startCountUpAnimation() {
        displayedScore = 0
        animationStartDate = .now
        isAnimating = score > 0

        if score == 0 {
            stopCountUpAnimation()
        }
    }

    private func stopCountUpAnimation() {
        isAnimating = false
        animationStartDate = nil
    }

    private func updateDisplayedScore(at currentDate: Date) {
        guard isAnimating, let animationStartDate else {
            return
        }

        let elapsed = min(Self.animationDuration, currentDate.timeIntervalSince(animationStartDate))
        let progress = max(0.0, min(1.0, elapsed / Self.animationDuration))
        let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
        let nextScore = min(score, Int((Double(score) * easedProgress).rounded(.down)))
        displayedScore = nextScore

        if progress >= 1.0 {
            displayedScore = score
            stopCountUpAnimation()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    FinishView(score: 248)
}
