import SwiftUI
import UIKit

struct ScorecardView: View {
    let result: ScoreResult
    let playerName: String?

    static let cardSize = CGSize(width: 390, height: 600)
    static let logoAssetName = "ScorecardLogo"

    private static let cornerRadius: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.08, blue: 0.20),
                            Color(red: 0.13, green: 0.24, blue: 0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }

            VStack(spacing: 18) {
                Image(Self.logoAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .padding(.top, 10)

                if let playerName, !playerName.isEmpty {
                    Text(playerName)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text("\(result.score)")
                    .font(.system(size: 94, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(result.title.localizedName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.14), in: Capsule())

                if let playedAt = result.playedAt {
                    Text(playedAt, format: .dateTime.year().month().day())
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 4)
                }

                Spacer()

                Text("TapBurst")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 26)
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
    }
}

@MainActor
func generateScorecardImage(result: ScoreResult, playerName: String?) -> UIImage? {
    let renderer = ImageRenderer(content: ScorecardView(result: result, playerName: playerName))
    renderer.proposedSize = ProposedViewSize(
        width: ScorecardView.cardSize.width,
        height: ScorecardView.cardSize.height
    )
    renderer.scale = 2.0
    return renderer.uiImage
}

#Preview(traits: .landscapeLeft) {
    ScorecardView(
        result: ScoreResult(
            score: 321,
            cps: 32.1,
            title: TitleDefinition.title(for: 321),
            isNewBest: true,
            playedAt: .now
        ),
        playerName: "Player One"
    )
}
