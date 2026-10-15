import Foundation

/// Dois senos: esquerda em `carrier`, direita em `carrier + beat`.
public struct BinauralGenerator {
    private var phaseL: Float = 0
    private var phaseR: Float = 0
    private let twoPi = Float.pi * 2

    public init() {}

    public mutating func reset() {
        phaseL = 0; phaseR = 0
    }

    @inline(__always)
    public mutating func next(carrier: Float, beat: Float, sampleRate: Float) -> (Float, Float) {
        phaseL += twoPi * carrier / sampleRate
        phaseR += twoPi * (carrier + beat) / sampleRate
        if phaseL >= twoPi { phaseL -= twoPi }
        if phaseR >= twoPi { phaseR -= twoPi }
        return (sinf(phaseL) * 0.3, sinf(phaseR) * 0.3)
    }
}
