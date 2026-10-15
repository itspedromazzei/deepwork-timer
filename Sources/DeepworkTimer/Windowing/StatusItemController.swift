import AppKit
import DeepworkCore

/// Item na barra de menus com o tempo restante e ações rápidas.
@MainActor
final class StatusItemController {
    private let item: NSStatusItem
    private let engine: TimerEngine
    private let startPauseItem: NSMenuItem

    init(engine: TimerEngine, target: AppDelegate) {
        self.engine = engine
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        startPauseItem = NSMenuItem(title: Strings.start, action: #selector(AppDelegate.startOrPause(_:)), keyEquivalent: "")
        startPauseItem.target = target
        menu.addItem(startPauseItem)
        let stop = NSMenuItem(title: Strings.stop, action: #selector(AppDelegate.stopTimer(_:)), keyEquivalent: "")
        stop.target = target
        menu.addItem(stop)
        menu.addItem(.separator())
        let toggle = NSMenuItem(title: Strings.toggleMode, action: #selector(AppDelegate.toggleWindowMode(_:)), keyEquivalent: "")
        toggle.target = target
        menu.addItem(toggle)
        let show = NSMenuItem(title: Strings.showWindow, action: #selector(AppDelegate.showWindow(_:)), keyEquivalent: "")
        show.target = target
        menu.addItem(show)
        menu.addItem(.separator())
        menu.addItem(withTitle: Strings.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        item.menu = menu
        update()
    }

    func update() {
        guard let button = item.button else { return }
        switch engine.state {
        case .idle:
            button.title = ""
            button.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: Strings.appName)
            startPauseItem.title = Strings.start
        case .countdown(let step):
            button.image = nil
            button.title = "\(step)…"
            startPauseItem.title = Strings.start
        case .running(let kind, _):
            button.image = nil
            let prefix = kind == .breakTime ? "☕ " : ""
            button.title = prefix + TimeFormatting.clock(engine.remainingSeconds)
            startPauseItem.title = Strings.pause
        case .paused:
            button.image = nil
            button.title = "⏸ " + TimeFormatting.clock(engine.remainingSeconds)
            startPauseItem.title = Strings.resume
        }
    }
}
