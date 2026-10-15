import Foundation

/// Lê e grava sessions.json e settings.json em Application Support.
/// Escrita atômica; arquivo corrompido é renomeado e começa-se do zero.
public final class Store: @unchecked Sendable {
    public let directory: URL
    public var sessionsURL: URL { directory.appendingPathComponent("sessions.json") }
    public var settingsURL: URL { directory.appendingPathComponent("settings.json") }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var pendingSettingsSave: DispatchWorkItem?
    private let queue = DispatchQueue(label: "com.pedromazzei.DeepworkTimer.store")

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("DeepworkTimer", isDirectory: true)
    }

    public init(directory: URL = Store.defaultDirectory()) {
        self.directory = directory
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - Sessões

    public func loadSessions() -> [Session] {
        load([Session].self, from: sessionsURL) ?? []
    }

    public func saveSessions(_ sessions: [Session]) {
        let url = sessionsURL
        queue.async { [encoder] in
            if let data = try? encoder.encode(sessions) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    // MARK: - Configurações

    public func loadSettings() -> AppSettings {
        load(AppSettings.self, from: settingsURL) ?? AppSettings()
    }

    /// Grava com debounce de 0,5 s (sliders disparam muitas mudanças).
    public func saveSettingsDebounced(_ settings: AppSettings, delay: TimeInterval = 0.5) {
        pendingSettingsSave?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.saveSettingsNow(settings) }
        pendingSettingsSave = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    public func saveSettingsNow(_ settings: AppSettings) {
        pendingSettingsSave?.cancel()
        pendingSettingsSave = nil
        if let data = try? encoder.encode(settings) {
            try? data.write(to: settingsURL, options: .atomic)
        }
    }

    /// Garante que gravações pendentes terminem (chamar ao sair).
    public func flush() {
        queue.sync {}
    }

    // MARK: - Interno

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.appendingPathExtension("corrupt-\(stamp)")
            try? FileManager.default.moveItem(at: url, to: backup)
            return nil
        }
    }
}
