import SwiftUI

struct GameHUDView: View {
    let score: Int
    let remainingTime: TimeInterval

    private static let scoreFontSize: CGFloat = 80
    private static let timeFontSize: CGFloat = 36
    private static let timerTopPadding: CGFloat = 24
    private static let horizontalPadding: CGFloat = 32

    var body: some View {
        ZStack {
            Text("\(score)")
                .font(.system(size: Self.scoreFontSize, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            VStack {
                HStack {
                    Spacer()
                    Text(String(format: "%.1f", max(0, remainingTime)))
                        .font(.system(size: Self.timeFontSize, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                Spacer()
            }
        }
        .padding(.top, Self.timerTopPadding)
        .padding(.horizontal, Self.horizontalPadding)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    GameHUDView(score: 128, remainingTime: 6.7)
        .background(Color.black)
}
