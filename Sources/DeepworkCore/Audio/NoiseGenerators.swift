/// Ruído rosa via filtro de Paul Kellet (pk3). Entrada: ruído branco em [-1, 1].
public struct PinkNoise {
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0
    private var b4: Float = 0, b5: Float = 0, b6: Float = 0

    public init() {}

    public mutating func reset() {
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0
    }

    @inline(__always)
    public mutating func next(_ w: Float) -> Float {
        b0 = 0.99886 * b0 + w * 0.0555179
        b1 = 0.99332 * b1 + w * 0.0750759
        b2 = 0.96900 * b2 + w * 0.1538520
        b3 = 0.86650 * b3 + w * 0.3104856
        b4 = 0.55000 * b4 + w * 0.5329522
        b5 = -0.7616 * b5 - w * 0.0168980
        let pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11
        b6 = w * 0.115926
        return pink
    }
}

/// Ruído marrom: integrador com vazamento + bloqueio de DC.
public struct BrownNoise {
    private var acc: Float = 0
    private var x1: Float = 0
    private var y1: Float = 0

    public init() {}

    public mutating func reset() {
        acc = 0; x1 = 0; y1 = 0
    }

    @inline(__always)
    public mutating func next(_ w: Float) -> Float {
        acc = (acc + 0.02 * w) / 1.02
        let x = acc * 3.5
        let y = x - x1 + 0.995 * y1
        x1 = x
        y1 = y
        return min(1, max(-1, y))
    }
}
