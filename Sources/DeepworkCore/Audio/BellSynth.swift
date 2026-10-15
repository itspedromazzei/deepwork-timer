import Foundation

/// Síntese aditiva de um sino e dos bipes da contagem. Renderiza uma vez, em mono.
public enum BellSynth {
    struct Partial {
        let ratio: Float
        let amp: Float
        let tau: Float
    }

    static let partials: [Partial] = [
        Partial(ratio: 1.0, amp: 1.0, tau: 1.6),
        Partial(ratio: 2.0, amp: 0.55, tau: 1.1),
        Partial(ratio: 3.01, amp: 0.35, tau: 0.8),
        Partial(ratio: 4.2, amp: 0.22, tau: 0.6),
        Partial(ratio: 5.4, amp: 0.14, tau: 0.45),
        Partial(ratio: 6.8, amp: 0.08, tau: 0.3),
    ]

    /// Sino de ~3 s em dó5 (523,25 Hz), pico normalizado para 0,7 × volume.
    public static func renderBell(sampleRate: Float = 48_000, volume: Float = 1, duration: Float = 3.0,
                                  baseFrequency: Float = 523.25) -> [Float] {
        let n = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: n)
        let attackSamples = max(1, Int(0.004 * sampleRate))
        let twoPi = Float.pi * 2
        for p in partials {
            let w = twoPi * baseFrequency * p.ratio / sampleRate
            var phase: Float = 0
            let decayPerSample = expf(-1 / (p.tau * sampleRate))
            var env = p.amp
            for i in 0..<n {
                out[i] += env * sinf(phase)
                phase += w
                if phase >= twoPi { phase -= twoPi }
                env *= decayPerSample
            }
        }
        for i in 0..<min(attackSamples, n) {
            out[i] *= Float(i) / Float(attackSamples)
        }
        normalize(&out, peak: 0.7 * min(1, max(0, volume)))
        return out
    }

    /// Bipe curto para a contagem 3-2-1 (880 Hz) e o "vai" (1320 Hz).
    public static func renderBlip(frequency: Float = 880, sampleRate: Float = 48_000,
                                  duration: Float = 0.06, volume: Float = 0.3) -> [Float] {
        let n = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: n)
        let twoPi = Float.pi * 2
        let w = twoPi * frequency / sampleRate
        let decayPerSample = expf(-1 / (0.02 * sampleRate))
        var env: Float = 1
        var phase: Float = 0
        let attack = max(1, Int(0.002 * sampleRate))
        for i in 0..<n {
            let a = i < attack ? Float(i) / Float(attack) : 1
            out[i] = sinf(phase) * env * a
            phase += w
            if phase >= twoPi { phase -= twoPi }
            env *= decayPerSample
        }
        normalize(&out, peak: min(1, max(0, volume)))
        return out
    }

    static func normalize(_ buf: inout [Float], peak: Float) {
        var maxAbs: Float = 0
        for v in buf { maxAbs = max(maxAbs, abs(v)) }
        guard maxAbs > 0 else { return }
        let k = peak / maxAbs
        for i in buf.indices { buf[i] *= k }
    }
}
