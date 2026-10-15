import Foundation

/// Gera o som de foco em blocos estéreo Float32. Puro DSP, sem AVFoundation.
/// Todo o estado é pré-alocado: nada de alocação, lock ou Foundation no caminho de render.
public final class FocusRenderer {
    public let params: AudioParameters
    public let sampleRate: Float

    private var rngL: Xorshift
    private var rngR: Xorshift
    private var pinkL = PinkNoise()
    private var pinkR = PinkNoise()
    private var brownL = BrownNoise()
    private var brownR = BrownNoise()
    private var binaural = BinauralGenerator()

    private var currentGain: Float = 0
    private var lastMode: AudioMode

    public init(params: AudioParameters, sampleRate: Float) {
        self.params = params
        self.sampleRate = sampleRate
        self.lastMode = params.mode
        rngL = Xorshift(seed: 0xA5A5_1234)
        rngR = Xorshift(seed: 0x5A5A_4321)
    }

    /// Ganho atual após a rampa (útil para saber se já silenciou).
    public var isSilent: Bool { currentGain <= 0.0001 && params.targetGain <= 0.0001 }

    public func render(frameCount: Int, left: UnsafeMutablePointer<Float>, right: UnsafeMutablePointer<Float>) {
        let mode = params.mode
        let target = params.targetGain
        let ramp = max(0.001, params.rampSeconds)
        let step = 1 / (ramp * sampleRate)
        let carrier = params.carrierHz
        let beat = params.beatHz

        if mode != lastMode {
            lastMode = mode
            currentGain = 0
            pinkL.reset(); pinkR.reset()
            brownL.reset(); brownR.reset()
            binaural.reset()
        }

        var g = currentGain
        switch mode {
        case .white:
            for i in 0..<frameCount {
                g = Self.approach(g, target, step)
                left[i] = rngL.nextFloat() * g
                right[i] = rngR.nextFloat() * g
            }
        case .pink:
            for i in 0..<frameCount {
                g = Self.approach(g, target, step)
                left[i] = Self.clamp(pinkL.next(rngL.nextFloat())) * g
                right[i] = Self.clamp(pinkR.next(rngR.nextFloat())) * g
            }
        case .brown:
            for i in 0..<frameCount {
                g = Self.approach(g, target, step)
                left[i] = brownL.next(rngL.nextFloat()) * g
                right[i] = brownR.next(rngR.nextFloat()) * g
            }
        case .binauralBeta, .binauralGamma:
            for i in 0..<frameCount {
                g = Self.approach(g, target, step)
                let (l, r) = binaural.next(carrier: carrier, beat: beat, sampleRate: sampleRate)
                left[i] = l * g
                right[i] = r * g
            }
        }
        currentGain = g
    }

    @inline(__always)
    private static func approach(_ g: Float, _ target: Float, _ step: Float) -> Float {
        if g < target { return min(target, g + step) }
        if g > target { return max(target, g - step) }
        return g
    }

    @inline(__always)
    private static func clamp(_ x: Float) -> Float {
        min(1, max(-1, x))
    }
}
