import SwiftUI
import UIKit

struct ResultsView: View {
    @Bindable var gameManager: GameManager
    @State private var showingPlayerNameInput = false
    @State private var showingSaveResultAlert = false
    @State private var saveResultMessage = ""
    @State private var playerNameSubmission: PlayerNameInputView.Submission?
    @State private var shouldResumeShareAfterDismiss = false

    private let shareService = ShareService()

    private static let heroSpacing: CGFloat = 18
    private static let buttonSpacing: CGFloat = 14
    private static let contentSpacing: CGFloat = 28

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .warm)

            if let result = gameManager.result {
                content(result: result)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
            }
        }
        .sheet(isPresented: $showingPlayerNameInput, onDismiss: handlePlayerNameDismiss) {
            PlayerNameInputView(
                initialName: gameManager.playerName,
                onComplete: { submission in
                    playerNameSubmission = submission
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert(saveResultMessage, isPresented: $showingSaveResultAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func content(result: ScoreResult) -> some View {
        HStack(alignment: .center, spacing: Self.contentSpacing) {
            VStack(alignment: .leading, spacing: Self.heroSpacing) {
                Text(String(localized: "results.score"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .accessibilityHidden(true)

                Text("\(result.score)")
                    .font(.system(size: 112, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .accessibilityHidden(true)

                Text(result.title.localizedName)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.14), in: Capsule())
                    .accessibilityHidden(true)

                if result.isNewBest {
                    Text(String(localized: "results.new_best"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(String(localized: "results.score")), \(String(localized: "a11y.results.title_label"))"))
            .accessibilityValue(Text("\(result.score), \(result.title.localizedName)"))
            .accessibilityAddTraits(.isStaticText)
            .accessibilitySortPriority(8)

            if result.isNewBest {
                Color.clear
                    .frame(width: 0, height: 0)
                    .accessibilityLabel(Text(String(localized: "results.new_best")))
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilitySortPriority(7)
            }

            VStack(spacing: Self.buttonSpacing) {
                actionButton(
                    title: String(localized: "results.retry"),
                    color: .orange,
                    hint: String(localized: "a11y.results.retry_hint"),
                    sortPriority: 3,
                    action: gameManager.retry
                )

                actionButton(
                    title: String(localized: "results.share"),
                    color: .blue,
                    hint: String(localized: "a11y.results.share_hint"),
                    sortPriority: 3
                ) {
                    beginShareFlow()
                }

                actionButton(
                    title: String(localized: "results.save"),
                    color: .green,
                    hint: String(localized: "a11y.results.save_hint"),
                    sortPriority: 2
                ) {
                    saveScore(result: result)
                }

                actionButton(
                    title: String(localized: "results.go_home"),
                    color: .gray,
                    hint: String(localized: "a11y.results.home_hint"),
                    sortPriority: 1,
                    action: gameManager.goHome
                )
            }
            .padding(20)
            .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func actionButton(
        title: String,
        color: Color,
        hint: String,
        sortPriority: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            actionButtonLabel(title: title, color: color)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(hint))
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
    private func beginShareFlow() {
        if gameManager.playerName == nil {
            shouldResumeShareAfterDismiss = true
            showingPlayerNameInput = true
            return
        }
        shareScoreIfPossible()
    }

    @MainActor
    private func shareScoreIfPossible() {
        guard let result = gameManager.result,
              let image = generateScorecardImage(result: result, playerName: gameManager.playerName) else {
            return
        }
        shareService.shareScorecard(image: image, score: result.score)
    }

    private func saveScore(result: ScoreResult) {
        Task {
            guard let image = await MainActor.run(body: {
                generateScorecardImage(result: result, playerName: gameManager.playerName)
            }) else {
                await MainActor.run {
                    saveResultMessage = String(localized: "results.save_failed")
                    showingSaveResultAlert = true
                }
                return
            }

            do {
                try await shareService.saveToPhotoLibrary(image: image)
                await MainActor.run {
                    saveResultMessage = String(localized: "results.save_success")
                    showingSaveResultAlert = true
                }
            } catch ShareService.PhotoLibraryError.permissionDenied {
                await shareService.presentPhotoLibraryDeniedAlert()
            } catch {
                await MainActor.run {
                    saveResultMessage = String(localized: "results.save_denied")
                    showingSaveResultAlert = true
                }
            }
        }
    }

    @MainActor
    private func handlePlayerNameDismiss() {
        guard shouldResumeShareAfterDismiss else {
            playerNameSubmission = nil
            return
        }

        defer {
            shouldResumeShareAfterDismiss = false
            playerNameSubmission = nil
        }

        if case let .save(name) = playerNameSubmission {
            gameManager.savePlayerName(name)
        }

        shareScoreIfPossible()
    }
}

#Preview(traits: .landscapeLeft) {
    let manager = GameManager()
    manager.result = ScoreResult(
        score: 250,
        cps: 25.0,
        title: TitleDefinition.title(for: 250),
        isNewBest: true,
        playedAt: .now
    )
    return ResultsView(gameManager: manager)
}
