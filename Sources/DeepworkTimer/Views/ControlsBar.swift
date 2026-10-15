import SwiftUI
import DeepworkCore

struct ControlsBar: View {
    @Bindable var model: AppModel
    var engine: TimerEngine
    var ui: UIState
    let actions: AppActions

    private var selectedActivity: Activity? {
        model.settings.activities.first { $0.id == ui.selectedActivityID && !$0.archived } ?? model.settings.lastActivity
    }

    var body: some View {
        VStack(spacing: 10) {
            if engine.state.isIdle {
                activityMenu
            }
            HStack(spacing: 8) {
                switch engine.state {
                case .idle:
                    Button(action: actions.startOrPause) {
                        Label(Strings.start, systemImage: "play.fill")
                    }
                    .buttonStyle(PillButtonStyle(prominent: true))
                case .countdown:
                    Button(Strings.stop, action: actions.stop)
                        .buttonStyle(PillButtonStyle())
                case .running(let kind, _):
                    Button(action: actions.startOrPause) {
                        Label(Strings.pause, systemImage: "pause.fill")
                    }
                    .buttonStyle(PillButtonStyle())
                    if kind == .breakTime {
                        Button(Strings.skipBreak, action: actions.skipBreak)
                            .buttonStyle(PillButtonStyle(prominent: true, tint: Theme.breakColor))
                    }
                    Button(Strings.stop, action: actions.stop)
                        .buttonStyle(PillButtonStyle())
                case .paused(let kind, _):
                    Button(action: actions.startOrPause) {
                        Label(Strings.resume, systemImage: "play.fill")
                    }
                    .buttonStyle(PillButtonStyle(prominent: true, tint: kind == .focus ? Theme.focus : Theme.breakColor))
                    Button(Strings.stop, action: actions.stop)
                        .buttonStyle(PillButtonStyle())
                }
            }
        }
    }

    private var activityMenu: some View {
        Menu {
            ForEach(model.settings.activeActivities) { a in
                Button {
                    ui.selectedActivityID = a.id
                    model.settings.lastActivityID = a.id
                } label: {
                    if a.id == selectedActivity?.id {
                        Label(a.name, systemImage: "checkmark")
                    } else {
                        Text(a.name)
                    }
                }
            }
            Divider()
            Button(Strings.editActivities) { ui.overlay = .activities }
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(selectedActivity.map { Theme.activityColor($0.colorIndex) } ?? Theme.faint)
                    .frame(width: 8, height: 8)
                Text(selectedActivity?.name ?? Strings.newActivity)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.control))
            .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
