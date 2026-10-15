import Foundation

/// Modos de som de foco. Todos sintetizados em tempo real.
public enum AudioMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case white
    case pink
    case brown
    case binauralBeta
    case binauralGamma

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .white: return "Ruído branco"
        case .pink: return "Ruído rosa"
        case .brown: return "Ruído marrom"
        case .binauralBeta: return "Binaural beta"
        case .binauralGamma: return "Binaural gama (40 Hz)"
        }
    }

    public var isBinaural: Bool {
        self == .binauralBeta || self == .binauralGamma
    }

    /// Índice estável usado nos parâmetros atômicos do render de áudio.
    public var index: UInt32 {
        UInt32(AudioMode.allCases.firstIndex(of: self) ?? 0)
    }

    public init(index: UInt32) {
        let all = AudioMode.allCases
        let i = Int(index)
        self = (i >= 0 && i < all.count) ? all[i] : .brown
    }
}
