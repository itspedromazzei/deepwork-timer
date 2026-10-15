import Foundation

public enum TimerState: Equatable, Sendable {
    case idle
    /// Contagem 3-2-1 antes do foco.
    case countdown(step: Int)
    case running(kind: SessionKind, endsAt: Date)
    case paused(kind: SessionKind, remaining: TimeInterval)

    public var isIdle: Bool { if case .idle = self { return true } else { return false } }
    public var isCountdown: Bool { if case .countdown = self { return true } else { return false } }
    public var isRunning: Bool { if case .running = self { return true } else { return false } }
    public var isPaused: Bool { if case .paused = self { return true } else { return false } }
    public var isActive: Bool { !isIdle }

    public var kind: SessionKind? {
        switch self {
        case .running(let k, _), .paused(let k, _): return k
        case .countdown: return .focus
        case .idle: return nil
        }
    }
}
