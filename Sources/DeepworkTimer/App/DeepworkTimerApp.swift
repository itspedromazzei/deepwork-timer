import AppKit

@main
@MainActor
struct DeepworkTimerApp {
    // Mantém o delegate vivo pelo tempo de vida do processo.
    private static var delegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let d = AppDelegate()
        delegate = d
        app.delegate = d
        app.setActivationPolicy(.regular)
        app.run()
    }
}
