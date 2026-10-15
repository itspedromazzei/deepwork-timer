import SwiftUI
import DeepworkCore

struct RootView: View {
    @Bindable var model: AppModel
    var engine: TimerEngine
    var ui: UIState
    let actions: AppActions

    @State private var hideTask: Task<Void, Never>?

    private var isCover: Bool { ui.windowMode == .cover }

    private var controlsShown: Bool {
        if !isCover || !engine.state.isRunning { return true }
        return ui.controlsVisible
    }

    private var currentActivityName: String? {
        if engine.state.isIdle {
            return (model.settings.activities.first { $0.id == ui.selectedActivityID } ?? model.settings.lastActivity)?.name
        }
        return engine.activity?.name
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar
                    .opacity(controlsShown ? 1 : 0)
                TimerView(engine: engine, activityName: currentActivityName)
                    .padding(.horizontal, 12)
                ControlsBar(model: model, engine: engine, ui: ui, actions: actions)
                    .padding(.bottom, isCover ? 48 : 18)
                    .padding(.horizontal, 12)
                    .opacity(controlsShown ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.25), value: controlsShown)

            overlay
        }
        .onContinuousHover { phase in
            guard isCover else { return }
            switch phase {
            case .active:
                ui.controlsVisible = true
                scheduleHide()
            case .ended:
                scheduleHide(after: 1.5)
            }
        }
        .onChange(of: engine.state.isRunning) { _, running in
            if running { scheduleHide() } else { ui.controlsVisible = true }
        }
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        Group {
            if isCover {
                Theme.background
            } else {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.background)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.cardBorder))
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            Spacer()
            Button { ui.overlay = ui.overlay == .history ? .none : .history } label: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(IconButtonStyle())
            .help(Strings.history)
            Button { actions.refreshScreens(); ui.overlay = ui.overlay == .settings ? .none : .settings } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(IconButtonStyle())
            .help(Strings.settings)
            Button(action: actions.toggleWindowMode) {
                Image(systemName: isCover ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(IconButtonStyle())
            .help(Strings.toggleMode)
        }
        .padding(.horizontal, 14)
        .padding(.top, isCover ? 20 : 14)
    }

    @ViewBuilder
    private var overlay: some View {
        switch ui.overlay {
        case .none:
            EmptyView()
        case .settings:
            OverlayCard(title: Strings.settings, onClose: closeOverlay) {
                SettingsView(model: model, ui: ui, actions: actions)
            }
            .transition(.opacity)
        case .history:
            OverlayCard(title: Strings.history, onClose: closeOverlay) {
                HistoryView(model: model)
            }
            .transition(.opacity)
        case .activities:
            OverlayCard(title: Strings.editActivities.replacingOccurrences(of: "…", with: ""), onClose: closeOverlay) {
                ActivitiesEditorView(model: model, ui: ui)
            }
            .transition(.opacity)
        }
    }

    private func closeOverlay() {
        if ui.isPreviewingAudio { actions.stopPreview() }
        withAnimation(.easeInOut(duration: 0.15)) { ui.overlay = .none }
    }

    private func scheduleHide(after seconds: Double = 3) {
        hideTask?.cancel()
        guard isCover, engine.state.isRunning else { return }
        hideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            if ui.overlay == .none { ui.controlsVisible = false }
        }
    }
}
