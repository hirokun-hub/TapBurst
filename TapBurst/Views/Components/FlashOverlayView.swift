import SwiftUI

struct FlashOverlayView: View {
    let opacity: Double

    var body: some View {
        Color.white
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

#Preview(traits: .landscapeLeft) {
    FlashOverlayView(opacity: 0.3)
}
