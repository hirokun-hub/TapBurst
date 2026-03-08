import SwiftUI
import UIKit

struct GameTouchView: UIViewRepresentable {
    let phase: GamePhase
    let particleTier: CPSTier
    let onTap: ([CGPoint]) -> Void

    func makeUIView(context: Context) -> TouchDetectionView {
        let view = TouchDetectionView()
        view.currentPhase = phase
        view.currentParticleTier = particleTier
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: TouchDetectionView, context: Context) {
        uiView.currentPhase = phase
        uiView.currentParticleTier = particleTier
        uiView.onTap = onTap
    }
}

final class TouchDetectionView: UIView {
    var onTap: (([CGPoint]) -> Void)?
    var currentPhase: GamePhase = .home
    var currentParticleTier: CPSTier = .t0

    private let maxSimultaneousEmitters = 5
    private let emitterStopDelay: TimeInterval = 0.05
    private let emitterRemoveDelay: TimeInterval = 0.5
    private var activeEmitterCount = 0

    private static let particleTexture: CGImage? = {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 32, height: 32)
        )
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.95).cgColor)
            context.cgContext.fillEllipse(in: rect.insetBy(dx: 8, dy: 8))
        }
        return image.cgImage
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase == .playing else {
            return
        }

        let positions = touches.map { $0.location(in: self) }
        for position in positions {
            spawnParticleEmitter(at: position)
        }

        onTap?(positions)
        super.touchesBegan(touches, with: event)
    }

    private func spawnParticleEmitter(at point: CGPoint) {
        guard activeEmitterCount < maxSimultaneousEmitters else {
            return
        }

        let config = ParticleConfig.config(for: currentParticleTier)
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = point
        emitter.emitterShape = .point
        emitter.renderMode = .additive
        emitter.birthRate = 1.0

        let cell = CAEmitterCell()
        cell.contents = Self.particleTexture
        cell.birthRate = config.birthRate
        cell.lifetime = config.lifetime
        cell.lifetimeRange = config.lifetime * 0.25
        cell.velocity = config.velocity
        cell.velocityRange = config.velocityRange
        cell.scale = config.scale
        cell.scaleRange = config.scaleRange
        cell.scaleSpeed = config.scaleSpeed
        cell.alphaSpeed = -2.2
        cell.emissionRange = .pi * 2
        cell.spinRange = .pi
        cell.color = config.color

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
        activeEmitterCount += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + emitterStopDelay) { [weak emitter] in
            emitter?.birthRate = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + emitterRemoveDelay) { [weak self, weak emitter] in
            emitter?.removeFromSuperlayer()
            guard let self else {
                return
            }
            self.activeEmitterCount = max(0, self.activeEmitterCount - 1)
        }
    }
}
