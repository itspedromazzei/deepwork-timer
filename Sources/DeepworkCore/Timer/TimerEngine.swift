import Foundation
import Observation

public struct TimerConfig: Equatable, Sendable {
    public var focusSeconds: Int
    public var breakSeconds: Int
    public var autoStartBreak: Bool
    public var autoStartNextFocus: Bool
    public var countdownSteps: Int

    public init(focusSeconds: Int = 50 * 60, breakSeconds: Int = 10 * 60,
                autoStartBreak: Bool = true, autoStartNextFocus: Bool = false, countdownSteps: Int = 3) {
        self.focusSeconds = focusSeconds
        self.breakSeconds = breakSeconds
        self.autoStartBreak = autoStartBreak
        self.autoStartNextFocus = autoStartNextFocus
        self.countdownSteps = countdownSteps
    }

    public init(settings: AppSettings) {
        self.init(focusSeconds: settings.focusSeconds, breakSeconds: settings.breakSeconds,
                  autoStartBreak: settings.autoStartBreak, autoStartNextFocus: settings.autoStartNextFocus)
    }
}

/// Máquina de estados do timer. Única fonte de verdade para views, status item e áudio.
/// O tempo restante é sempre derivado de `endsAt` e do relógio, nunca de ticks acumulados.
@MainActor
@Observable
public final class TimerEngine {
    public private(set) var state: TimerState = .idle
    public private(set) var remainingSeconds: Int = 0
    public private(set) var plannedSeconds: Int = 0
    public private(set) var activity: Activity?

    public var config: TimerConfig

    /// Ponte para consumidores AppKit (status item, áudio, notificações, gravação).
    @ObservationIgnored public var onEvent: ((TimerEvent) -> Void)?

    @ObservationIgnored private let scheduler: TickScheduling
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var token: TickToken?

    @ObservationIgnored private var phaseStartedAt: Date?
    @ObservationIgnored private var accumulatedRunning: TimeInterval = 0
    @ObservationIgnored private var runningSince: Date?

    public init(config: TimerConfig = TimerConfig(),
                scheduler: TickScheduling? = nil,
                now: @escaping () -> Date = Date.init) {
        self.config = config
        self.scheduler = scheduler ?? FoundationTickScheduler()
        self.now = now
    }

    /// 1.0 no início da fase, 0.0 no fim.
    public var progress: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, Double(remainingSeconds) / Double(plannedSeconds)))
    }

    // MARK: - Comandos

    public func start(activity: Activity?) {
        guard state.isIdle else { return }
        self.activity = activity
        beginCountdown()
    }

    public func togglePause() {
        switch state {
        case .running(let kind, let endsAt):
            let n = now()
            if let since = runningSince { accumulatedRunning += n.timeIntervalSince(since) }
            runningSince = nil
            cancelTicks()
            state = .paused(kind: kind, remaining: max(0, endsAt.timeIntervalSince(n)))
            emit(.paused)
        case .paused(let kind, let remaining):
            let n = now()
            runningSince = n
            state = .running(kind: kind, endsAt: n.addingTimeInterval(remaining))
            scheduleTicks()
            emit(.resumed)
        default:
            break
        }
    }

    /// Para o que estiver rodando e volta para idle.
    public func stop() {
        switch state {
        case .idle:
            return
        case .countdown:
            cancelTicks()
            state = .idle
            emit(.cancelled)
        case .running, .paused:
            endPhase(completed: false)
            state = .idle
            remainingSeconds = 0
        }
    }

    public func skipBreak() {
        guard state.kind == .breakTime else { return }
        endPhase(completed: false)
        if config.autoStartNextFocus {
            beginCountdown()
        } else {
            state = .idle
            remainingSeconds = 0
        }
    }

    /// Chamado antes do Mac dormir.
    public func pauseIfRunning() {
        if state.isRunning { togglePause() }
    }

    /// Recalcula o tempo restante imediatamente (ex.: ao acordar).
    public func refresh() {
        tick()
    }

    // MARK: - Interno

    private func beginCountdown() {
        guard config.countdownSteps > 0 else {
            beginPhase(.focus)
            return
        }
        state = .countdown(step: config.countdownSteps)
        remainingSeconds = 0
        plannedSeconds = 0
        emit(.countdownTick(config.countdownSteps))
        scheduleTicks()
    }

    private func beginPhase(_ kind: SessionKind) {
        let planned = kind == .focus ? config.focusSeconds : config.breakSeconds
        let n = now()
        plannedSeconds = planned
        remainingSeconds = planned
        phaseStartedAt = n
        accumulatedRunning = 0
        runningSince = n
        state = .running(kind: kind, endsAt: n.addingTimeInterval(TimeInterval(planned)))
        emit(.phaseStarted(kind, activity: kind == .focus ? activity : nil, plannedSeconds: planned))
        scheduleTicks()
    }

    private func endPhase(completed: Bool) {
        guard let kind = state.kind, let startedAt = phaseStartedAt else { return }
        let n = now()
        if let since = runningSince { accumulatedRunning += n.timeIntervalSince(since) }
        runningSince = nil
        cancelTicks()
        let actual = completed ? plannedSeconds : Int(accumulatedRunning.rounded())
        emit(.phaseEnded(kind, activity: kind == .focus ? activity : nil, startedAt: startedAt, endedAt: n,
                         plannedSeconds: plannedSeconds, actualSeconds: actual, completed: completed))
        phaseStartedAt = nil
    }

    private func tick() {
        switch state {
        case .countdown(let step):
            let next = step - 1
            if next >= 1 {
                state = .countdown(step: next)
                emit(.countdownTick(next))
            } else {
                cancelTicks()
                beginPhase(.focus)
            }
        case .running(let kind, let endsAt):
            let rem = endsAt.timeIntervalSince(now())
            if rem <= 0.5 {
                remainingSeconds = 0
                endPhase(completed: true)
                advanceAfter(kind)
            } else {
                remainingSeconds = Int(rem.rounded())
                emit(.tick(remainingSeconds: remainingSeconds))
            }
        case .idle, .paused:
            break
        }
    }

    private func advanceAfter(_ kind: SessionKind) {
        switch kind {
        case .focus:
            if config.autoStartBreak && config.breakSeconds > 0 {
                beginPhase(.breakTime)
            } else {
                state = .idle
            }
        case .breakTime:
            if config.autoStartNextFocus {
                beginCountdown()
            } else {
                state = .idle
            }
        }
    }

    private func scheduleTicks() {
        cancelTicks()
        token = scheduler.schedule(firstFire: now().addingTimeInterval(1), interval: 1) { [weak self] in
            self?.tick()
        }
    }

    private func cancelTicks() {
        token?.cancel()
        token = nil
    }

    private func emit(_ event: TimerEvent) {
        onEvent?(event)
    }
}
