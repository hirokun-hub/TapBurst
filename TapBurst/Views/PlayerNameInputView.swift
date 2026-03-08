import SwiftUI

struct PlayerNameInputView: View {
    enum Submission {
        case save(String)
        case skip
    }

    @Environment(\.dismiss) private var dismiss

    @State private var playerName: String

    private let onComplete: (Submission) -> Void

    private static let playerNameCharacterLimit = 12

    init(
        initialName: String?,
        onComplete: @escaping (Submission) -> Void
    ) {
        _playerName = State(initialValue: initialName ?? "")
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(String(localized: "player_name.message"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField(String(localized: "player_name.placeholder"), text: $playerName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onChange(of: playerName) { _, newValue in
                        if newValue.count > Self.playerNameCharacterLimit {
                            playerName = String(newValue.prefix(Self.playerNameCharacterLimit))
                        }
                    }

                Spacer()

                HStack(spacing: 12) {
                    Button(String(localized: "player_name.skip")) {
                        onComplete(.skip)
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button(String(localized: "player_name.save")) {
                        onComplete(.save(playerName))
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(24)
            .navigationTitle(String(localized: "player_name.title"))
        }
    }
}
