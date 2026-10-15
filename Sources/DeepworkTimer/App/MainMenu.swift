import AppKit
import DeepworkCore

/// Menu principal construído em código (não há MainMenu.nib sem Xcode).
enum MainMenu {
    @MainActor
    static func install(target: AppDelegate) {
        let main = NSMenu()

        // Menu do app
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Sobre o \(Strings.appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(item("\(Strings.settings)…", #selector(AppDelegate.showSettings(_:)), ",", target))
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Ocultar \(Strings.appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "Ocultar outros", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Mostrar todos", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "\(Strings.quit) do \(Strings.appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // Editar (necessário para copiar/colar nos campos de texto)
        let editItem = NSMenuItem(title: "Editar", action: nil, keyEquivalent: "")
        main.addItem(editItem)
        let edit = NSMenu(title: "Editar")
        editItem.submenu = edit
        edit.addItem(withTitle: "Desfazer", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Refazer", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Recortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Colar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Selecionar tudo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        // Timer
        let timerItem = NSMenuItem(title: "Timer", action: nil, keyEquivalent: "")
        main.addItem(timerItem)
        let timer = NSMenu(title: "Timer")
        timerItem.submenu = timer
        timer.addItem(item("\(Strings.start) / \(Strings.pause)", #selector(AppDelegate.startOrPause(_:)), "", target))
        timer.addItem(item(Strings.stop, #selector(AppDelegate.stopTimer(_:)), ".", target))
        let skip = item(Strings.skipBreak, #selector(AppDelegate.skipBreak(_:)), ".", target)
        skip.keyEquivalentModifierMask = [.command, .shift]
        timer.addItem(skip)
        timer.addItem(.separator())
        timer.addItem(item(Strings.editActivities, #selector(AppDelegate.showActivities(_:)), "e", target))

        // Janela
        let windowItem = NSMenuItem(title: "Janela", action: nil, keyEquivalent: "")
        main.addItem(windowItem)
        let window = NSMenu(title: "Janela")
        windowItem.submenu = window
        let toggle = item(Strings.toggleMode, #selector(AppDelegate.toggleWindowMode(_:)), "f", target)
        toggle.keyEquivalentModifierMask = [.command, .shift]
        window.addItem(toggle)
        window.addItem(item(Strings.history, #selector(AppDelegate.showHistory(_:)), "y", target))
        window.addItem(.separator())
        window.addItem(item(Strings.showWindow, #selector(AppDelegate.showWindow(_:)), "1", target))

        NSApp.mainMenu = main
    }

    @MainActor
    private static func item(_ title: String, _ action: Selector, _ key: String, _ target: AnyObject) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = target
        return i
    }
}
