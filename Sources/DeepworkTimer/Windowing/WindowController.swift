import AppKit
import SwiftUI
import DeepworkCore

/// Controla a janela única: modo flutuante ou cobrindo uma tela inteira.
@MainActor
final class WindowController: NSObject, NSWindowDelegate {
    let window: MainWindow
    private let model: AppModel
    private let ui: UIState
    private var applying = false

    static let defaultFloatingSize = NSSize(width: 340, height: 400)

    init(model: AppModel, ui: UIState, content: NSView) {
        self.model = model
        self.ui = ui
        window = MainWindow(contentRect: NSRect(origin: .zero, size: Self.defaultFloatingSize),
                            styleMask: [.borderless, .resizable], backing: .buffered, defer: false)
        super.init()
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.title = Strings.appName
        window.contentView = content
        window.delegate = self
        window.animationBehavior = .none

        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.ui.windowMode == .cover else { return }
                self.apply(mode: .cover)
            }
        }
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func toggleMode() {
        apply(mode: ui.windowMode == .cover ? .floating : .cover)
    }

    func apply(mode: WindowMode) {
        applying = true
        defer { applying = false }
        ui.windowMode = mode
        if model.settings.windowMode != mode { model.settings.windowMode = mode }

        switch mode {
        case .floating:
            window.styleMask = [.borderless, .resizable]
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.isMovableByWindowBackground = true
            window.hasShadow = true
            window.minSize = NSSize(width: 240, height: 260)
            window.maxSize = NSSize(width: 4000, height: 4000)
            if let saved = model.settings.floatingFrame, !saved.isEmpty {
                window.setFrame(from: saved)
                if window.frame.size.width < 240 || !isOnSomeScreen(window.frame) {
                    centerDefault()
                }
            } else {
                centerDefault()
            }
        case .cover:
            let screen = resolveCoverScreen()
            window.styleMask = [.borderless]
            window.level = .statusBar
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            window.isMovableByWindowBackground = false
            window.hasShadow = false
            window.minSize = NSSize(width: 100, height: 100)
            window.maxSize = NSSize(width: 20000, height: 20000)
            window.setFrame(screen.frame, display: true)
        }
        window.invalidateShadow()
        show()
    }

    private func centerDefault() {
        let screen = NSScreen.screens.first ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = Self.defaultFloatingSize
        let origin = NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func isOnSomeScreen(_ frame: NSRect) -> Bool {
        NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
    }

    // MARK: - Telas

    static func displayID(of screen: NSScreen) -> UInt32? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }

    func availableScreens() -> [ScreenInfo] {
        NSScreen.screens.compactMap { s in
            guard let id = Self.displayID(of: s) else { return nil }
            return ScreenInfo(id: id, name: s.localizedName)
        }
    }

    func resolveCoverScreen() -> NSScreen {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return NSScreen.main! }
        if let id = model.settings.fullscreenDisplayID,
           let s = screens.first(where: { Self.displayID(of: $0) == id }) {
            return s
        }
        if let name = model.settings.fullscreenDisplayName,
           model.settings.fullscreenDisplayID != nil,
           let s = screens.first(where: { $0.localizedName == name }) {
            return s
        }
        // Automático: a primeira tela que não é a principal (a que tem a barra de menus).
        return screens.first { $0 != primary } ?? primary
    }

    // MARK: - NSWindowDelegate

    func windowDidMove(_ notification: Notification) { persistFloatingFrame() }
    func windowDidEndLiveResize(_ notification: Notification) { persistFloatingFrame() }

    private func persistFloatingFrame() {
        guard !applying, ui.windowMode == .floating else { return }
        model.settings.floatingFrame = window.frameDescriptor
    }
}
