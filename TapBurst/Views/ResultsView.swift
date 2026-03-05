import SwiftUI
import UIKit

struct ResultsView: View {
    @Bindable var gameManager: GameManager

    private static let sectionSpacing: CGFloat = 16
    private static let buttonSpacing: CGFloat = 14

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .warm)

            if let result = gameManager.result {
                content(result: result)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
            }
        }
    }

    @ViewBuilder
    private func content(result: ScoreResult) -> some View {
        VStack(spacing: Self.sectionSpacing) {
            metricRow(
                label: String(localized: "results.score"),
                value: "\(result.score)",
                sortPriority: 8
            )

            metricRow(
                label: String(localized: "results.cps"),
                value: String(format: "%.1f", result.cps),
                sortPriority: 7
            )

            metricRow(
                label: String(localized: "results.max_touches"),
                value: "\(result.maxSimultaneousTouches)",
                sortPriority: 6
            )

            metricRow(
                label: String(localized: "a11y.results.title_label"),
                value: result.title.localizedName,
                sortPriority: 5
            )

            if result.isNewBest {
                Text(String(localized: "results.new_best"))
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.yellow)
                    .accessibilitySortPriority(4)
            }

            VStack(spacing: Self.buttonSpacing) {
                Button {
                    gameManager.retry()
                } label: {
                    actionButtonLabel(title: String(localized: "results.retry"), color: .orange)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(String(localized: "a11y.results.retry_hint")))
                .accessibilitySortPriority(3)

                Button {
                    shareScore(result: result)
                } label: {
                    actionButtonLabel(title: String(localized: "results.share"), color: .blue)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(String(localized: "a11y.results.share_hint")))
                .accessibilitySortPriority(2)

                Button {
                    gameManager.goHome()
                } label: {
                    actionButtonLabel(title: String(localized: "results.go_home"), color: .gray)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(String(localized: "a11y.results.home_hint")))
                .accessibilitySortPriority(1)
            }
            .padding(.top, 10)
        }
    }

    private func metricRow(label: String, value: String, sortPriority: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Text(value)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(value))
        .accessibilityAddTraits(.isStaticText)
        .accessibilitySortPriority(sortPriority)
    }

    private func actionButtonLabel(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 28, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @MainActor
    private func shareScore(result: ScoreResult) {
        guard let image = generateScorecardImage(result: result) else {
            return
        }
        shareScorecard(image: image)
    }

    private func shareScorecard(image: UIImage) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        rootViewController.present(activityVC, animated: true)
    }
}

#Preview {
    let manager = GameManager()
    manager.result = ScoreResult(
        score: 250,
        cps: 25.0,
        maxSimultaneousTouches: 5,
        title: TitleDefinition.title(for: 250),
        isNewBest: true,
        playedAt: .now
    )
    return ResultsView(gameManager: manager)
}
