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

#Preview {
    FlashOverlayView(opacity: 0.3)
}
