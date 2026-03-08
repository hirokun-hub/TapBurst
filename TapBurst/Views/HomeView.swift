import SwiftUI

struct HomeView: View {
    @Bindable var gameManager: GameManager

    @State private var showingResetConfirmation = false
    @State private var showingPlayerNameInput = false
    @State private var playerNameSubmission: PlayerNameInputView.Submission?
    @State private var shouldResumeShareAfterDismiss = false

    private let shareService = ShareService()

    private static let columnSpacing: CGFloat = 32

    var body: some View {
        ZStack {
            BackgroundEffectView(timeStage: .calm)

            HStack(alignment: .center, spacing: Self.columnSpacing) {
                leftColumn
                rightColumn
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
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
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TapBurst")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .orange.opacity(0.8), radius: 12)
                .shadow(color: .orange.opacity(0.4), radius: 24)

            scorePanel

            resetButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scorePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "home.best_score"))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(bestScoreText)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    if gameManager.bestScore > 0 {
                        Text(TitleDefinition.title(for: gameManager.bestScore).localizedName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                if gameManager.bestScore > 0 {
                    Button(action: beginShareFlow) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(String(localized: "home.share_best")))
                    .accessibilityHint(Text(String(localized: "a11y.home.share_best_hint")))
                    .accessibilitySortPriority(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "home.today_best"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Text(todayBestText)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))
            }

            if showDifference {
                Text("home.until_new_best \(gameManager.bestScore - gameManager.todayBestScore)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.yellow.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var resetButton: some View {
        Button {
            showingResetConfirmation = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12))
                Text(String(localized: "a11y.home.reset_label"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.35))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(String(localized: "a11y.home.reset_label")))
        .accessibilityHint(Text(String(localized: "a11y.home.reset_hint")))
        .accessibilitySortPriority(2)
        .confirmationDialog(
            String(localized: "home.reset_confirmation_title"),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "home.reset_all"), role: .destructive) {
                gameManager.resetScores()
            }
        }
    }

    // MARK: - Right Column

    private var rightColumn: some View {
        Button {
            gameManager.startGame()
        } label: {
            Text(String(localized: "home.start"))
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .phaseAnimator([false, true]) { content, phase in
            content.scaleEffect(phase ? 1.04 : 1.0)
        } animation: { _ in
            .easeInOut(duration: 1.0)
        }
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
        .accessibilityLabel(Text(String(localized: "home.start")))
        .accessibilityHint(Text(String(localized: "a11y.home.start_hint")))
        .accessibilitySortPriority(1)
    }

    // MARK: - Helpers

    private var bestScoreText: String {
        gameManager.bestScore == 0 ? "---" : "\(gameManager.bestScore)"
    }

    private var todayBestText: String {
        gameManager.todayBestScore == 0 ? "---" : "\(gameManager.todayBestScore)"
    }

    private var showDifference: Bool {
        gameManager.todayBestScore > 0 && gameManager.todayBestScore < gameManager.bestScore
    }

    @MainActor
    private func beginShareFlow() {
        if gameManager.playerName == nil {
            shouldResumeShareAfterDismiss = true
            showingPlayerNameInput = true
            return
        }
        shareBestScore()
    }

    @MainActor
    private func shareBestScore() {
        guard let snapshot = gameManager.bestScoreSnapshot else {
            return
        }

        let result = ScoreResult(
            score: snapshot.score,
            cps: snapshot.cps,
            title: TitleDefinition.title(for: snapshot.score),
            isNewBest: false,
            playedAt: snapshot.playedAt
        )

        guard let image = generateScorecardImage(result: result, playerName: gameManager.playerName) else {
            return
        }

        shareService.shareScorecard(image: image, score: snapshot.score)
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

        shareBestScore()
    }
}

#Preview(traits: .landscapeLeft) {
    HomeView(gameManager: GameManager())
}
