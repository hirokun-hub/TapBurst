import UIKit
import QuartzCore

final class HapticsService {
    private let minimumInterval: TimeInterval = 0.016
    private var lastTriggerTime: TimeInterval = 0
    private let generator = UIImpactFeedbackGenerator(style: .light)

    init() {
        generator.prepare()
    }

    func triggerTapFeedback() {
        let now = CACurrentMediaTime()
        guard now - lastTriggerTime >= minimumInterval else {
            return
        }

        lastTriggerTime = now
        generator.impactOccurred()
    }
}
