import SwiftUI
import DeepworkCore

struct TimerView: View {
    var engine: TimerEngine
    var activityName: String?

    private var color: Color {
        switch engine.state {
        case .countdown: return Theme.countdown
        case .running(let kind, _), .paused(let kind, _): return kind == .focus ? Theme.focus : Theme.breakColor
        case .idle: return Theme.focus
        }
    }

    private var label: String {
        switch engine.state {
        case .countdown: return Strings.prepare
        case .running(let kind, _), .paused(let kind, _): return kind == .focus ? Strings.focus : Strings.breakTime
        case .idle: return Strings.focus
        }
    }

    private var progress: Double {
        switch engine.state {
        case .idle, .countdown: return 1
        case .running, .paused: return engine.progress
        }
    }

    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height) * 0.78
            ZStack {
                RingView(progress: progress, color: color, lineWidth: max(4, d * 0.045))
                    .frame(width: d, height: d)
                    .opacity(engine.state.isPaused ? 0.45 : 1)
                    .animation(.easeInOut(duration: 0.3), value: engine.state.isPaused)

                VStack(spacing: d * 0.03) {
                    Text(label)
                        .font(.system(size: max(9, d * 0.05), weight: .semibold))
                        .tracking(d * 0.012)
                        .foregroundStyle(Theme.faint)
                    Group {
                        if case .countdown(let step) = engine.state {
                            CountdownView(step: step, size: d * 0.3)
                        } else {
                            Text(timeText)
                                .font(.system(size: d * 0.22, weight: .light, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.text)
                                .contentTransition(.numericText(countsDown: true))
                        }
                    }
                    .frame(height: d * 0.3)
                    .animation(.easeOut(duration: 0.25), value: engine.state)
                    if let name = activityName, !name.isEmpty, engine.state.kind != .breakTime {
                        Text(name)
                            .font(.system(size: max(10, d * 0.055), weight: .regular))
                            .foregroundStyle(Theme.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: d * 0.7)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var timeText: String {
        switch engine.state {
        case .idle: return TimeFormatting.clock(engine.config.focusSeconds)
        default: return TimeFormatting.clock(engine.remainingSeconds)
        }
    }
}
