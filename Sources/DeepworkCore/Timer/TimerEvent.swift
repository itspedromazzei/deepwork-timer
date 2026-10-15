import Foundation

public enum TimerEvent: Equatable, Sendable {
    /// Passo da contagem regressiva (3, 2, 1).
    case countdownTick(Int)
    case phaseStarted(SessionKind, activity: Activity?, plannedSeconds: Int)
    case tick(remainingSeconds: Int)
    case paused
    case resumed
    case phaseEnded(SessionKind, activity: Activity?, startedAt: Date, endedAt: Date,
                    plannedSeconds: Int, actualSeconds: Int, completed: Bool)
    /// Contagem cancelada antes de começar o foco.
    case cancelled
}
