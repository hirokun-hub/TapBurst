import Observation
import QuartzCore
import SwiftUI
import UIKit
import Darwin

@MainActor
@Observable
final class GameManager {
    var phase: GamePhase = .home

    var session: GameSession?
    var result: ScoreResult?
    var remainingTime: TimeInterval = 10.0
    var currentCPS: Int = 0
    var currentTimeStage: TimeStage = .calm
    var currentCPSTier: CPSTier = .t0

    var shakeOffset: CGSize = .zero
    var flashOpacity: Double = 0.0
    var countdownNumber: Int? = nil
    var invalidTapOverlayOpacity: Double = 0.0

    var bestScore: Int = 0
    var todayBestScore: Int = 0

    private let scoreStore: ScoreStore
    private let audioService: AudioService
    private let hapticsService: HapticsService

    private var displayLink: CADisplayLink?
    private var countdownTimer: Timer?
    private var finishTransitionWorkItem: DispatchWorkItem?
    private var lastFlashTime: TimeInterval = 0.0

    private let gameDuration: TimeInterval = 10.0
    private let minimumTapInterval: TimeInterval = 1.0 / 60.0
    private let countdownStart = 3
    private let finishDuration: TimeInterval = 1.5
    private let maxShakeAmplitude: CGFloat = 5.0
    private let tapRateNormalizationUpperBound = 20.0
    private let flashInterval: TimeInterval = 0.7
    private let flashPeakOpacity = 0.3
    private let flashFadeDuration: TimeInterval = 0.25
    private let invalidShakeAmplitude: CGFloat = 2.0

    private var reduceMotionFactor: CGFloat {
        UIAccessibility.isReduceMotionEnabled ? 0.5 : 1.0
    }

    init(
        scoreStore: ScoreStore,
        audioService: AudioService,
        hapticsService: HapticsService
    ) {
        self.scoreStore = scoreStore
        self.audioService = audioService
        self.hapticsService = hapticsService
        bestScore = scoreStore.bestScore
        todayBestScore = scoreStore.todayBestScore
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
        currentCPSTier = .t0

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

    func registerTap() {
        guard phase == .playing, var session else {
            return
        }

        let now = CACurrentMediaTime()
        guard now - session.lastValidTapTime >= minimumTapInterval else {
            return
        }

        session.score += 1
        session.lastValidTapTime = now
        session.tapTimestamps.append(now)
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
        todayBestScore = scoreStore.todayBestScore
        resetEffects()
    }

    func resetScores() {
        scoreStore.resetAll()
        bestScore = 0
        todayBestScore = 0
    }

    func handleBackground() {
        guard phase == .countdown || phase == .playing || phase == .finish else {
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
        currentCPSTier = .t0
        resetEffects()
    }

    func handleForeground() {
        guard phase == .home else { return }
        todayBestScore = scoreStore.todayBestScore
    }

    private func beginPlaying() {
        phase = .playing
        session = GameSession(startTime: CACurrentMediaTime())
        remainingTime = gameDuration
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .t0
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
        scoreStore.updateTodayIfNeeded(score: score)
        todayBestScore = scoreStore.todayBestScore

        result = ScoreResult(
            score: score,
            title: TitleDefinition.title(for: score),
            isNewBest: isNewBest,
            playedAt: Date()
        )

        phase = .finish
        self.session = session
        remainingTime = 0.0
        currentCPS = 0
        currentTimeStage = .calm
        currentCPSTier = .t0
        countdownNumber = nil
        resetEffects()

        audioService.playFinish()

        let transitionWorkItem = DispatchWorkItem { [weak self] in
            guard let self, self.phase == .finish else {
                return
            }
            self.phase = .results
            self.session = nil
        }
        finishTransitionWorkItem = transitionWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + finishDuration, execute: transitionWorkItem)
    }

    private func updateEffects(elapsed: TimeInterval) {
        let tapRateFactor = min(1.0, Double(currentCPS) / tapRateNormalizationUpperBound)
        let normalizedElapsed = min(1.0, max(0.0, elapsed / gameDuration))
        let timeFactor = 0.18 + 0.82 * pow(normalizedElapsed, 1.6)
        let shakeAmplitude = maxShakeAmplitude * CGFloat(tapRateFactor * timeFactor) * reduceMotionFactor

        shakeOffset = CGSize(
            width: CGFloat.random(in: -shakeAmplitude...shakeAmplitude),
            height: CGFloat.random(in: -shakeAmplitude...shakeAmplitude)
        )

        if currentTimeStage == .intense {
            if elapsed - lastFlashTime >= flashInterval {
                lastFlashTime = elapsed
            }

            let timeSinceFlash = elapsed - lastFlashTime
            let fadeProgress = min(1.0, max(0.0, timeSinceFlash / flashFadeDuration))
            flashOpacity = flashPeakOpacity * (1.0 - fadeProgress)
            return
        }

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
        finishTransitionWorkItem?.cancel()
        finishTransitionWorkItem = nil
    }

    private func resetEffects() {
        shakeOffset = .zero
        flashOpacity = 0.0
        invalidTapOverlayOpacity = 0.0
    }
}
