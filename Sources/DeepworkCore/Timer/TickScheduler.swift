import Foundation

@MainActor
public protocol TickToken: AnyObject {
    func cancel()
}

/// Abstrai o Timer de 1 Hz para que o motor seja testável com relógio manual.
@MainActor
public protocol TickScheduling {
    func schedule(firstFire: Date, interval: TimeInterval, _ action: @escaping @MainActor () -> Void) -> TickToken
}

@MainActor
public final class FoundationTickScheduler: TickScheduling {
    public init() {}

    final class Token: TickToken {
        let timer: Timer
        init(_ timer: Timer) { self.timer = timer }
        func cancel() { timer.invalidate() }
    }

    public func schedule(firstFire: Date, interval: TimeInterval, _ action: @escaping @MainActor () -> Void) -> TickToken {
        let timer = Timer(fire: firstFire, interval: interval, repeats: true) { _ in
            MainActor.assumeIsolated { action() }
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        return Token(timer)
    }
}
