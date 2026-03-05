import Observation
import QuartzCore
import SwiftUI
import UIKit

@MainActor
@Observable
final class GameManager {
    var phase: GamePhase = .home

    var session: GameSession?
    var result: ScoreResult?
    var remainingTime: TimeInterval = 10.0
    var currentCPS: Int = 0
    var currentTimeStage: TimeStage = .calm
    var currentCPSTier: CPSTier = .normal

    var shakeOffset: CGSize = .zero
    var flashOpacity: Double = 0.0
    var countdownNumber: Int? = nil
    var invalidTapOverlayOpacity: Double = 0.0

    var bestScore: Int = 0

    private let scoreStore: ScoreStore
    private let audioService: AudioService
    private let hapticsService: HapticsService

    private var displayLink: CADisplayLink?
    private var countdownTimer: Timer?
    private var lastFlashTime: TimeInterval = 0.0

    private let gameDuration: TimeInterval = 10.0
    private let countdownStart = 3
    private let shakeAmplitude: CGFloat = 3.0
    private let flashInterval: TimeInterval = 0.7
    private let invalidShakeAmplitude: CGFloat = 2.0

    init(
        scoreStore: ScoreStore,
        audioService: AudioService,
        hapticsService: HapticsService
    ) {
        self.scoreStore = scoreStore
        self.audioService = audioService
        self.hapticsService = hapticsService
        bestScore = scoreStore.bestScore
    }

    convenience init() {
        self.init(
            scoreStore: ScoreStore(),
            audioService: AudioService(),
            hapticsService: HapticsService()
        )
    }

    func startGame() {
        stopActiveLoops()
        UIApplication.shared.isIdleTimerDisabled = true

        phase = .countdown
        session = nil
        result = nil

        remainingTime = gameDuration
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .normal

        shakeOffset = .zero
        flashOpacity = 0.0
        invalidTapOverlayOpacity = 0.0
        lastFlashTime = 0.0

        countdownNumber = countdownStart
        audioService.playCountdownTick(number: countdownStart)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            if let number = self.countdownNumber, number > 1 {
                let nextNumber = number - 1
                self.countdownNumber = nextNumber
                self.audioService.playCountdownTick(number: nextNumber)
                return
            }

            timer.invalidate()
            self.countdownTimer = nil
            self.countdownNumber = nil
            self.audioService.playGo()
            self.beginPlaying()
        }
    }

    func registerInvalidCountdownTap() {
        guard phase == .countdown else {
            return
        }

        withAnimation(.spring(duration: 0.3, bounce: 0.25)) {
            shakeOffset = CGSize(
                width: CGFloat.random(in: -invalidShakeAmplitude...invalidShakeAmplitude),
                height: CGFloat.random(in: -invalidShakeAmplitude...invalidShakeAmplitude)
            )
        }

        withAnimation(.spring(duration: 0.3).delay(0.1)) {
            shakeOffset = .zero
        }

        invalidTapOverlayOpacity = 0.3
        withAnimation(.easeOut(duration: 0.5)) {
            invalidTapOverlayOpacity = 0.0
        }
    }

    func registerTaps(count: Int, positions _: [CGPoint]) {
        guard phase == .playing, count > 0, var session else {
            return
        }

        let now = CACurrentMediaTime()

        session.score += count
        session.maxSimultaneousTouches = max(session.maxSimultaneousTouches, count)
        session.tapTimestamps.append(contentsOf: Array(repeating: now, count: count))
        pruneOldTimestamps(in: &session, now: now)

        currentCPS = session.tapTimestamps.count
        currentCPSTier = CPSTier.tier(for: currentCPS)
        self.session = session

        audioService.playTapSound(tier: currentCPSTier)
        hapticsService.triggerTapFeedback()
    }

    func retry() {
        result = nil
        session = nil
        startGame()
    }

    func goHome() {
        stopActiveLoops()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .home
        session = nil
        result = nil
        resetEffects()
    }

    func handleBackground() {
        guard phase == .countdown || phase == .playing else {
            return
        }

        stopActiveLoops()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .home
        session = nil
        result = nil
        countdownNumber = nil
        remainingTime = gameDuration
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .normal
        resetEffects()
    }

    private func beginPlaying() {
        phase = .playing
        session = GameSession(startTime: CACurrentMediaTime())
        remainingTime = gameDuration
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .normal
        lastFlashTime = 0.0
        resetEffects()

        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(displayLinkFired(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc
    private func displayLinkFired(_: CADisplayLink) {
        guard phase == .playing, var session else {
            return
        }

        let now = CACurrentMediaTime()
        let elapsed = now - session.startTime
        remainingTime = max(0.0, gameDuration - elapsed)

        if elapsed >= gameDuration {
            endGame(using: session)
            return
        }

        pruneOldTimestamps(in: &session, now: now)
        currentCPS = session.tapTimestamps.count
        currentTimeStage = TimeStage.stage(at: elapsed)
        currentCPSTier = CPSTier.tier(for: currentCPS)

        updateEffects(elapsed: elapsed)
        self.session = session
    }

    private func endGame(using session: GameSession) {
        stopActiveLoops()
        UIApplication.shared.isIdleTimerDisabled = false

        let score = session.score
        let isNewBest = scoreStore.updateIfNeeded(score: score)
        bestScore = scoreStore.bestScore

        result = ScoreResult(
            score: score,
            cps: Double(score) / gameDuration,
            maxSimultaneousTouches: session.maxSimultaneousTouches,
            title: TitleDefinition.title(for: score),
            isNewBest: isNewBest,
            playedAt: Date()
        )

        phase = .results
        self.session = nil
        remainingTime = 0.0
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .normal
        countdownNumber = nil
        resetEffects()

        audioService.playFinish()
    }

    private func updateEffects(elapsed: TimeInterval) {
        if currentTimeStage == .intense {
            shakeOffset = CGSize(
                width: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
                height: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
            )

            if elapsed - lastFlashTime >= flashInterval {
                flashOpacity = 0.3
                lastFlashTime = elapsed
            } else {
                flashOpacity = max(0.0, flashOpacity - 0.02)
            }
            return
        }

        shakeOffset = .zero
        flashOpacity = 0.0
    }

    private func pruneOldTimestamps(in session: inout GameSession, now: TimeInterval) {
        let cutoff = now - 1.0
        session.tapTimestamps.removeAll { $0 < cutoff }
    }

    private func stopActiveLoops() {
        displayLink?.invalidate()
        displayLink = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func resetEffects() {
        shakeOffset = .zero
        flashOpacity = 0.0
        invalidTapOverlayOpacity = 0.0
    }
}
