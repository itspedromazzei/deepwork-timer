import AppKit
import SwiftUI
import DeepworkCore

/// Raiz de composição: cria tudo, liga os eventos do timer a áudio, notificações,
/// gravação de sessões, status item e janela.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = Store()
    private lazy var model = AppModel(store: store)
    private let ui = UIState()
    private lazy var engine = TimerEngine(config: TimerConfig(settings: model.settings))
    private let audio = AudioController()
    private let notifier = Notifier()
    private let keepAwake = KeepAwake()
    private var windowController: WindowController!
    private var statusItem: StatusItemController!

    private var settings: AppSettings { model.settings }

    // MARK: - Ciclo de vida

    func applicationWillFinishLaunching(_ notification: Notification) {
        MainMenu.install(target: self)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ui.windowMode = settings.windowMode
        ui.selectedActivityID = settings.lastActivity?.id

        engine.onEvent = { [weak self] event in self?.handle(event) }
        audio.onError = { [weak self] message in self?.ui.audioError = message }

        let root = RootView(model: model, engine: engine, ui: ui, actions: makeActions())
        let hosting = NSHostingView(rootView: root)
        hosting.sizingOptions = []
        windowController = WindowController(model: model, ui: ui, content: hosting)
        windowController.window.onSpace = { [weak self] in self?.startOrPause(nil) }
        windowController.window.onEscape = { [weak self] in self?.escape() }
        ui.screens = windowController.availableScreens()
        windowController.apply(mode: settings.windowMode)

        statusItem = StatusItemController(engine: engine, target: self)
        notifier.requestAuthorization()

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.engine.pauseIfRunning() }
        }
        ws.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.engine.refresh() }
        }
        NSApp.activate()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowController.show()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()   // grava a sessão parcial, se houver
        keepAwake.end()
        model.flush()
    }

    // MARK: - Eventos do timer

    private func handle(_ event: TimerEvent) {
        switch event {
        case .countdownTick(let step):
            if settings.countdownTicks { audio.playBlip(high: false) }
            if step == 1 { audio.prewarm() }

        case .phaseStarted(let kind, _, _):
            if kind == .focus {
                if settings.countdownTicks { audio.playBlip(high: true) }
                audio.startFocus(settings: settings)
                if settings.keepAwake { keepAwake.begin() }
            } else {
                if settings.audioDuringBreak { audio.startFocus(settings: settings) } else { audio.stopFocus() }
                keepAwake.end()
            }

        case .tick:
            break

        case .paused:
            audio.stopFocus()
            keepAwake.end()

        case .resumed:
            let kind = engine.state.kind
            if kind == .focus || settings.audioDuringBreak { audio.startFocus(settings: settings) }
            if kind == .focus && settings.keepAwake { keepAwake.begin() }

        case .phaseEnded(let kind, let activity, let startedAt, let endedAt, let planned, let actual, let completed):
            if actual >= 60 {
                model.record(Session(kind: kind, activityID: activity?.id, activityName: activity?.name ?? "",
                                     startedAt: startedAt, endedAt: endedAt, plannedSeconds: planned,
                                     actualSeconds: actual, completed: completed))
            }
            if completed {
                audio.playBell(volume: settings.bellVolume)
                notifier.phaseEnded(kind, activity: activity, plannedSeconds: planned)
            }
            if kind == .focus { keepAwake.end() }
            let breakWithAudioFollows = kind == .focus && completed && settings.autoStartBreak && settings.audioDuringBreak
            if !breakWithAudioFollows { audio.stopFocus() }

        case .cancelled:
            audio.stopFocus()
        }
        statusItem?.update()
    }

    // MARK: - Ações

    private func makeActions() -> AppActions {
        var a = AppActions()
        a.startOrPause = { [weak self] in self?.startOrPause(nil) }
        a.stop = { [weak self] in self?.stopTimer(nil) }
        a.skipBreak = { [weak self] in self?.skipBreak(nil) }
        a.toggleWindowMode = { [weak self] in self?.toggleWindowMode(nil) }
        a.previewAudio = { [weak self] in
            guard let self else { return }
            audio.preview(settings: settings)
            ui.isPreviewingAudio = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.1) { [weak self] in
                MainActor.assumeIsolated { self?.ui.isPreviewingAudio = self?.audio.isPreviewing ?? false }
            }
        }
        a.stopPreview = { [weak self] in
            self?.audio.stopPreview()
            self?.ui.isPreviewingAudio = false
        }
        a.previewBell = { [weak self] in
            guard let self else { return }
            audio.playBell(volume: settings.bellVolume)
        }
        a.audioSettingsChanged = { [weak self] in
            guard let self else { return }
            audio.apply(settings: settings)
        }
        a.refreshScreens = { [weak self] in
            guard let self else { return }
            ui.screens = windowController.availableScreens()
        }
        a.quit = { NSApp.terminate(nil) }
        return a
    }

    private func escape() {
        if ui.overlay != .none {
            ui.overlay = .none
            if ui.isPreviewingAudio { audio.stopPreview(); ui.isPreviewingAudio = false }
        } else if ui.windowMode == .cover {
            windowController.apply(mode: .floating)
        }
    }

    @objc func startOrPause(_ sender: Any?) {
        switch engine.state {
        case .idle:
            engine.config = TimerConfig(settings: settings)
            let activity = settings.activities.first { $0.id == ui.selectedActivityID && !$0.archived } ?? settings.lastActivity
            ui.selectedActivityID = activity?.id
            model.settings.lastActivityID = activity?.id
            ui.overlay = .none
            engine.start(activity: activity)
        case .running, .paused:
            engine.togglePause()
        case .countdown:
            break
        }
        statusItem?.update()
    }

    @objc func stopTimer(_ sender: Any?) {
        engine.stop()
        statusItem?.update()
    }

    @objc func skipBreak(_ sender: Any?) {
        engine.skipBreak()
        statusItem?.update()
    }

    @objc func toggleWindowMode(_ sender: Any?) {
        windowController.toggleMode()
    }

    @objc func showWindow(_ sender: Any?) {
        windowController.show()
    }

    @objc func showSettings(_ sender: Any?) {
        ui.screens = windowController.availableScreens()
        ui.overlay = ui.overlay == .settings ? .none : .settings
        windowController.show()
    }

    @objc func showHistory(_ sender: Any?) {
        ui.overlay = ui.overlay == .history ? .none : .history
        windowController.show()
    }

    @objc func showActivities(_ sender: Any?) {
        ui.overlay = ui.overlay == .activities ? .none : .activities
        windowController.show()
    }
}
