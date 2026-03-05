import Foundation
import AVFAudio

final class AudioService {
    private let tapPlayerPoolSize = 4
    private let preferredBufferSize = 64
    private let sampleRate: Double = 44_100

    private let engine = AVAudioEngine()
    private let eventPlayer = AVAudioPlayerNode()
    private var tapPlayers: [AVAudioPlayerNode] = []
    private var pitchUnits: [AVAudioUnitTimePitch] = []
    private var tapBuffer: AVAudioPCMBuffer?
    private var countdown3Buffer: AVAudioPCMBuffer?
    private var countdown2Buffer: AVAudioPCMBuffer?
    private var countdown1Buffer: AVAudioPCMBuffer?
    private var goBuffer: AVAudioPCMBuffer?
    private var finishBuffer: AVAudioPCMBuffer?
    private var currentPlayerIndex = 0

    init() {
        setup()
    }

    func playTapSound(tier: CPSTier) {
        guard let tapBuffer, !tapPlayers.isEmpty else {
            return
        }

        let index = currentPlayerIndex
        currentPlayerIndex = (currentPlayerIndex + 1) % tapPlayerPoolSize

        pitchUnits[index].pitch = PitchConfig.config(for: tier).pitchShift

        let player = tapPlayers[index]
        player.scheduleBuffer(tapBuffer, at: nil, options: .interrupts)
        if !player.isPlaying {
            player.play()
        }
    }

    func playCountdownTick(number: Int) {
        let buffer: AVAudioPCMBuffer?
        switch number {
        case 3:
            buffer = countdown3Buffer
        case 2:
            buffer = countdown2Buffer
        case 1:
            buffer = countdown1Buffer
        default:
            buffer = nil
        }

        playEventBuffer(buffer)
    }

    func playGo() {
        playEventBuffer(goBuffer)
    }

    func playFinish() {
        playEventBuffer(finishBuffer)
    }

    private func setup() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient)
            try session.setPreferredIOBufferDuration(Double(preferredBufferSize) / sampleRate)
            try session.setActive(true)

            for _ in 0..<tapPlayerPoolSize {
                let player = AVAudioPlayerNode()
                let pitchUnit = AVAudioUnitTimePitch()
                pitchUnit.bypass = false

                engine.attach(player)
                engine.attach(pitchUnit)
                engine.connect(player, to: pitchUnit, format: nil)
                engine.connect(pitchUnit, to: engine.mainMixerNode, format: nil)

                tapPlayers.append(player)
                pitchUnits.append(pitchUnit)
            }

            engine.attach(eventPlayer)
            engine.connect(eventPlayer, to: engine.mainMixerNode, format: nil)

            tapBuffer = loadBuffer(named: "tap")
            countdown3Buffer = loadBuffer(named: "countdown3")
            countdown2Buffer = loadBuffer(named: "countdown2")
            countdown1Buffer = loadBuffer(named: "countdown1")
            goBuffer = loadBuffer(named: "go")
            finishBuffer = loadBuffer(named: "finish")

            try engine.start()
        } catch {
            tapPlayers.removeAll()
            pitchUnits.removeAll()
        }
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else {
            return nil
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: frameCount
            ) else {
                return nil
            }
            try audioFile.read(into: buffer)
            return buffer
        } catch {
            return nil
        }
    }

    private func playEventBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer else {
            return
        }

        eventPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !eventPlayer.isPlaying {
            eventPlayer.play()
        }
    }
}
