import Foundation
import Testing
@testable import DeepworkCore

@MainActor
struct TimerEngineTests {
    let activity = Activity(name: "Meta Ads", colorIndex: 0)

    @Test func countdownThenFocusStarts() {
        let (engine, sched, _, log) = makeEngine()
        engine.start(activity: activity)
        #expect(engine.state == .countdown(step: 3))
        #expect(log.events.first == .countdownTick(3))

        sched.advance(by: 1)
        #expect(engine.state == .countdown(step: 2))
        sched.advance(by: 1)
        #expect(engine.state == .countdown(step: 1))
        sched.advance(by: 1)
        #expect(engine.state.isRunning)
        #expect(engine.state.kind == .focus)
        #expect(engine.remainingSeconds == 60)
        #expect(engine.plannedSeconds == 60)
        #expect(log.events.contains(.phaseStarted(.focus, activity: activity, plannedSeconds: 60)))
    }

    @Test func ticksCountDownAndProgressFalls() {
        let (engine, sched, _, _) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3)
        sched.advance(by: 10)
        #expect(engine.remainingSeconds == 50)
        #expect(abs(engine.progress - 50.0 / 60.0) < 0.001)
    }

    @Test func focusEndsCompletedAndAutoStartsBreak() {
        let (engine, sched, _, log) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3)
        sched.advance(by: 60)
        guard let ended = log.events.first(where: {
            if case .phaseEnded(.focus, _, _, _, _, _, _) = $0 { return true } else { return false }
        }) else { Issue.record("sem phaseEnded"); return }
        if case .phaseEnded(_, let a, _, _, let planned, let actual, let completed) = ended {
            #expect(a == activity)
            #expect(planned == 60)
            #expect(actual == 60)
            #expect(completed)
        }
        #expect(engine.state.isRunning)
        #expect(engine.state.kind == .breakTime)
        #expect(engine.remainingSeconds == 30)
    }

    @Test func breakEndsToIdleWithoutAutoNextFocus() {
        let (engine, sched, _, _) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3 + 60 + 30)
        #expect(engine.state == .idle)
    }

    @Test func breakEndsToCountdownWithAutoNextFocus() {
        var cfg = TimerConfig(focusSeconds: 60, breakSeconds: 30)
        cfg.autoStartNextFocus = true
        let (engine, sched, _, _) = makeEngine(config: cfg)
        engine.start(activity: activity)
        sched.advance(by: 3 + 60 + 30)
        #expect(engine.state == .countdown(step: 3))
    }

    @Test func noAutoBreakGoesIdle() {
        var cfg = TimerConfig(focusSeconds: 60, breakSeconds: 30)
        cfg.autoStartBreak = false
        let (engine, sched, _, _) = makeEngine(config: cfg)
        engine.start(activity: activity)
        sched.advance(by: 63)
        #expect(engine.state == .idle)
    }

    @Test func pauseFreezesRemainingAndResumeContinues() {
        let (engine, sched, _, log) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3 + 20)
        engine.togglePause()
        #expect(engine.state.isPaused)
        #expect(log.events.last == .paused)
        sched.advance(by: 100)   // tempo passa, nada muda
        #expect(engine.remainingSeconds == 40)
        engine.togglePause()
        #expect(log.events.last == .resumed)
        sched.advance(by: 10)
        #expect(engine.remainingSeconds == 30)
    }

    @Test func stopEarlyRecordsActualSecondsExcludingPauses() {
        let (engine, sched, _, log) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3 + 20)
        engine.togglePause()
        sched.advance(by: 50)
        engine.togglePause()
        sched.advance(by: 5)
        engine.stop()
        #expect(engine.state == .idle)
        guard case .phaseEnded(let kind, _, _, _, _, let actual, let completed)? = log.events.last else {
            Issue.record("sem phaseEnded"); return
        }
        #expect(kind == .focus)
        #expect(actual == 25)
        #expect(!completed)
    }

    @Test func stopDuringCountdownCancels() {
        let (engine, sched, _, log) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 1)
        engine.stop()
        #expect(engine.state == .idle)
        #expect(log.events.last == .cancelled)
        sched.advance(by: 10)
        #expect(engine.state == .idle)
    }

    @Test func skipBreakGoesIdle() {
        let (engine, sched, _, _) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 63)
        #expect(engine.state.kind == .breakTime)
        engine.skipBreak()
        #expect(engine.state == .idle)
    }

    @Test func pauseIfRunningOnlyAffectsRunning() {
        let (engine, sched, _, _) = makeEngine()
        engine.pauseIfRunning()
        #expect(engine.state == .idle)
        engine.start(activity: activity)
        sched.advance(by: 5)
        engine.pauseIfRunning()
        #expect(engine.state.isPaused)
    }

    @Test func refreshAfterLongGapFinishesPhase() {
        let (engine, sched, clock, _) = makeEngine()
        engine.start(activity: activity)
        sched.advance(by: 3)
        clock.now = clock.now.addingTimeInterval(500)  // relógio saltou sem ticks
        engine.refresh()
        #expect(engine.state.kind == .breakTime)
    }
}
