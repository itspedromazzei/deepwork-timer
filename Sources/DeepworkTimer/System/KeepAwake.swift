import Foundation

/// Impede a tela de apagar durante o foco. Libera sozinho se o processo morrer.
@MainActor
final class KeepAwake {
    private var token: NSObjectProtocol?

    func begin() {
        guard token == nil else { return }
        token = ProcessInfo.processInfo.beginActivity(
            options: [.idleDisplaySleepDisabled, .userInitiated],
            reason: "Sessão de foco em andamento"
        )
    }

    func end() {
        if let t = token {
            ProcessInfo.processInfo.endActivity(t)
            token = nil
        }
    }
}
