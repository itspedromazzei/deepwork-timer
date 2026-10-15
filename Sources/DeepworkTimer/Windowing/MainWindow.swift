import AppKit

/// Janela sem bordas que ainda recebe teclado.
final class MainWindow: NSWindow {
    var onSpace: (() -> Void)?
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        // Não roubar teclas de campos de texto em edição.
        if firstResponder is NSTextView {
            super.keyDown(with: event)
            return
        }
        switch event.keyCode {
        case 49: // espaço
            onSpace?()
        case 53: // esc
            onEscape?()
        default:
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
