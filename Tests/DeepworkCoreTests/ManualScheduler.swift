import Foundation
@testable import DeepworkCore

/// Relógio controlado pelo teste: `advance(by:)` move o tempo e dispara ticks devidos.
@MainActor
final class TestClock {
    var now: Date
    init(_ now: Date = Date(timeIntervalSince1970: 1_000_000)) { self.now = now }
}

@MainActor
final class ManualScheduler: TickScheduling {
    final class Token: TickToken {
        var cancelled = false
        func cancel() { cancelled = true }
    }

    struct Pending {
        var nextFire: Date
        let interval: TimeInterval
        let action: @MainActor () -> Void
        let token: Token
    }

    let clock: TestClock
    private var pending: Pending?

    init(clock: TestClock) { self.clock = clock }

    func schedule(firstFire: Date, interval: TimeInterval, _ action: @escaping @MainActor () -> Void) -> TickToken {
        let token = Token()
        pending = Pending(nextFire: firstFire, interval: interval, action: action, token: token)
        return token
    }

    /// Avança o relógio em segundos, disparando cada tick na sua hora exata.
    func advance(by seconds: TimeInterval) {
        let target = clock.now.addingTimeInterval(seconds)
        while let p = pending, !p.token.cancelled, p.nextFire <= target {
            clock.now = p.nextFire
            pending?.nextFire = p.nextFire.addingTimeInterval(p.interval)
            p.action()
        }
        if let p = pending, p.token.cancelled { pending = nil }
        clock.now = target
    }
}

@MainActor
func makeEngine(config: TimerConfig = TimerConfig(focusSeconds: 60, breakSeconds: 30)) -> (TimerEngine, ManualScheduler, TestClock, EventLog) {
    let clock = TestClock()
    let scheduler = ManualScheduler(clock: clock)
    let engine = TimerEngine(config: config, scheduler: scheduler, now: { clock.now })
    let log = EventLog()
    engine.onEvent = { log.events.append($0) }
    return (engine, scheduler, clock, log)
}

final class EventLog {
    var events: [TimerEvent] = []
}
