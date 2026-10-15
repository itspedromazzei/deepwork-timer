import Foundation
import UserNotifications
import DeepworkCore

/// Notificações do sistema. Sem bundle identifier (ex.: `swift run`) vira no-op,
/// porque UNUserNotificationCenter.current() aborta o processo nesse caso.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier != nil ? UNUserNotificationCenter.current() : nil
    }

    func requestAuthorization() {
        guard let center else { return }
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func post(title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Sem som: o sino do app já toca.
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }

    func phaseEnded(_ kind: SessionKind, activity: Activity?, plannedSeconds: Int) {
        let title = kind == .focus ? Strings.focusDone : Strings.breakDone
        var body = TimeFormatting.duration(plannedSeconds)
        if kind == .focus, let name = activity?.name { body = "\(name) — \(body)" }
        post(title: title, body: body)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
