import Foundation
import Synchronization

/// Parâmetros lidos pelo thread de áudio. Só atômicos, sem locks.
public final class AudioParameters: Sendable {
    let modeRaw: Atomic<UInt32>
    let gainBits: Atomic<UInt32>
    let rampBits: Atomic<UInt32>
    let beatBits: Atomic<UInt32>
    let carrierBits: Atomic<UInt32>

    public init(mode: AudioMode = .brown, gain: Float = 0, rampSeconds: Float = 0.03,
                beatHz: Float = 18, carrierHz: Float = 200) {
        modeRaw = Atomic(mode.index)
        gainBits = Atomic(gain.bitPattern)
        rampBits = Atomic(rampSeconds.bitPattern)
        beatBits = Atomic(beatHz.bitPattern)
        carrierBits = Atomic(carrierHz.bitPattern)
    }

    public var mode: AudioMode {
        get { AudioMode(index: modeRaw.load(ordering: .relaxed)) }
        set { modeRaw.store(newValue.index, ordering: .relaxed) }
    }

    /// Ganho alvo (0…1). O render faz a rampa até ele.
    public var targetGain: Float {
        get { Float(bitPattern: gainBits.load(ordering: .relaxed)) }
        set { gainBits.store(newValue.bitPattern, ordering: .relaxed) }
    }

    public var rampSeconds: Float {
        get { Float(bitPattern: rampBits.load(ordering: .relaxed)) }
        set { rampBits.store(newValue.bitPattern, ordering: .relaxed) }
    }

    public var beatHz: Float {
        get { Float(bitPattern: beatBits.load(ordering: .relaxed)) }
        set { beatBits.store(newValue.bitPattern, ordering: .relaxed) }
    }

    public var carrierHz: Float {
        get { Float(bitPattern: carrierBits.load(ordering: .relaxed)) }
        set { carrierBits.store(newValue.bitPattern, ordering: .relaxed) }
    }

    /// Converte o slider (0…1) em ganho perceptual, com ajuste por modo.
    public static func gain(forSlider slider: Double, mode: AudioMode) -> Float {
        let s = Float(min(1, max(0, slider)))
        let trim: Float
        switch mode {
        case .white: trim = 0.25
        case .pink: trim = 0.9
        case .brown: trim = 1.0
        case .binauralBeta, .binauralGamma: trim = 1.0
        }
        return s * s * trim
    }
}
