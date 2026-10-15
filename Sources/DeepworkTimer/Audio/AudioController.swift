import AppKit
import AVFoundation
import DeepworkCore

/// Um AVAudioEngine para tudo: som de foco (source node) e sino/bipes (player node).
/// O engine só roda enquanto há algo tocando; ocioso = zero CPU.
@MainActor
final class AudioController {
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
    private let params = AudioParameters()
    private let renderer: FocusRenderer
    private var sourceNode: AVAudioSourceNode!
    private let player = AVAudioPlayerNode()

    private var wantsFocus = false
    private var previewing = false
    private var bellsPlaying = 0
    private var stopWorkItem: DispatchWorkItem?
    private var previewWorkItem: DispatchWorkItem?

    private var bellBuffer: AVAudioPCMBuffer?
    private var bellBufferVolume: Float = -1
    private var blipLow: AVAudioPCMBuffer?
    private var blipHigh: AVAudioPCMBuffer?

    var onError: ((String?) -> Void)?

    init() {
        renderer = FocusRenderer(params: params, sampleRate: Float(format.sampleRate))
        let renderer = self.renderer
        sourceNode = AVAudioSourceNode(format: format) { _, _, frameCount, abl -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            guard buffers.count >= 2, let l = buffers[0].mData, let r = buffers[1].mData else { return noErr }
            renderer.render(frameCount: Int(frameCount),
                            left: l.assumingMemoryBound(to: Float.self),
                            right: r.assumingMemoryBound(to: Float.self))
            return noErr
        }
        engine.attach(sourceNode)
        engine.attach(player)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()

        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleConfigurationChange() }
        }
    }

    // MARK: - Som de foco

    func apply(settings: AppSettings) {
        params.mode = settings.audioMode
        params.carrierHz = Float(settings.binauralCarrierHz)
        params.beatHz = settings.audioMode == .binauralGamma ? 40 : Float(settings.binauralBeatHz)
        if wantsFocus || previewing {
            params.rampSeconds = 0.03
            params.targetGain = AudioParameters.gain(forSlider: settings.audioVolume, mode: settings.audioMode)
        }
    }

    /// Liga o engine com ganho zero para o som começar exatamente no "vai".
    func prewarm() {
        params.targetGain = 0
        ensureRunning()
    }

    func startFocus(settings: AppSettings) {
        wantsFocus = true
        stopWorkItem?.cancel()
        params.mode = settings.audioMode
        params.carrierHz = Float(settings.binauralCarrierHz)
        params.beatHz = settings.audioMode == .binauralGamma ? 40 : Float(settings.binauralBeatHz)
        params.rampSeconds = 1.0
        params.targetGain = AudioParameters.gain(forSlider: settings.audioVolume, mode: settings.audioMode)
        ensureRunning()
    }

    func stopFocus() {
        wantsFocus = false
        guard !previewing else { return }
        fadeOutAndStop()
    }

    func preview(settings: AppSettings, seconds: TimeInterval = 5) {
        previewing = true
        previewWorkItem?.cancel()
        stopWorkItem?.cancel()
        params.mode = settings.audioMode
        params.carrierHz = Float(settings.binauralCarrierHz)
        params.beatHz = settings.audioMode == .binauralGamma ? 40 : Float(settings.binauralBeatHz)
        params.rampSeconds = 0.3
        params.targetGain = AudioParameters.gain(forSlider: settings.audioVolume, mode: settings.audioMode)
        ensureRunning()
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.stopPreview() }
        }
        previewWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    func stopPreview() {
        previewWorkItem?.cancel()
        previewing = false
        if !wantsFocus { fadeOutAndStop() }
    }

    var isPreviewing: Bool { previewing }

    private func fadeOutAndStop() {
        params.rampSeconds = 1.5
        params.targetGain = 0
        stopWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.stopIfIdle() }
        }
        stopWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: item)
    }

    // MARK: - Sino e bipes

    func playBell(volume: Double) {
        let v = Float(volume)
        if bellBuffer == nil || abs(bellBufferVolume - v) > 0.001 {
            bellBuffer = makeBuffer(BellSynth.renderBell(sampleRate: Float(format.sampleRate), volume: v))
            bellBufferVolume = v
        }
        if let buf = bellBuffer { play(buf) }
    }

    func playBlip(high: Bool) {
        if high {
            if blipHigh == nil { blipHigh = makeBuffer(BellSynth.renderBlip(frequency: 1320, sampleRate: Float(format.sampleRate), duration: 0.09)) }
            if let b = blipHigh { play(b) }
        } else {
            if blipLow == nil { blipLow = makeBuffer(BellSynth.renderBlip(frequency: 880, sampleRate: Float(format.sampleRate))) }
            if let b = blipLow { play(b) }
        }
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        guard ensureRunning() else {
            NSSound(named: "Glass")?.play()
            return
        }
        bellsPlaying += 1
        player.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.bellsPlaying = max(0, self.bellsPlaying - 1)
                    self.stopIfIdle()
                }
            }
        }
        if !player.isPlaying { player.play() }
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return nil }
        buf.frameLength = AVAudioFrameCount(samples.count)
        guard let ch = buf.floatChannelData else { return nil }
        samples.withUnsafeBufferPointer { src in
            ch[0].update(from: src.baseAddress!, count: samples.count)
            ch[1].update(from: src.baseAddress!, count: samples.count)
        }
        return buf
    }

    // MARK: - Engine

    @discardableResult
    private func ensureRunning() -> Bool {
        stopWorkItem?.cancel()
        if engine.isRunning { return true }
        do {
            try engine.start()
            onError?(nil)
            return true
        } catch {
            onError?(Strings.noOutputDevice)
            return false
        }
    }

    private func stopIfIdle() {
        guard !wantsFocus, !previewing, bellsPlaying == 0 else { return }
        if !renderer.isSilent {
            // Ainda em rampa: tenta de novo em breve.
            let item = DispatchWorkItem { [weak self] in MainActor.assumeIsolated { self?.stopIfIdle() } }
            stopWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
            return
        }
        player.stop()
        engine.stop()
    }

    private func handleConfigurationChange() {
        // O engine para sozinho ao trocar o dispositivo de saída.
        guard wantsFocus || previewing || bellsPlaying > 0 else { return }
        engine.prepare()
        try? engine.start()
        if bellsPlaying > 0 { player.play() }
    }
}
