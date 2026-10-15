/// PRNG xorshift32: barato e sem locks, seguro para o thread de áudio.
public struct Xorshift {
    private var state: UInt32

    public init(seed: UInt32) {
        state = seed == 0 ? 0x9E37_79B9 : seed
    }

    @inline(__always)
    public mutating func next() -> UInt32 {
        var x = state
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        state = x
        return x
    }

    /// Uniforme em [-1, 1).
    @inline(__always)
    public mutating func nextFloat() -> Float {
        Float(next()) * (2.0 / 4_294_967_296.0) - 1.0
    }
}
