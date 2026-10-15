import Foundation
import Observation

/// Estado persistente do app em memória: configurações e sessões.
@MainActor
@Observable
public final class AppModel {
    public var settings: AppSettings {
        didSet { store.saveSettingsDebounced(settings) }
    }
    public private(set) var sessions: [Session]

    @ObservationIgnored private let store: Store

    public init(store: Store) {
        self.store = store
        self.settings = store.loadSettings()
        self.sessions = store.loadSessions()
    }

    public func record(_ session: Session) {
        sessions.append(session)
        store.saveSessions(sessions)
    }

    public func flush() {
        store.saveSettingsNow(settings)
        store.flush()
    }

    // MARK: - Atividades

    public func addActivity(named name: String) -> Activity {
        let used = Set(settings.activities.map(\.colorIndex))
        let color = (0..<Activity.paletteSize).first { !used.contains($0) } ?? settings.activities.count % Activity.paletteSize
        let a = Activity(name: name, colorIndex: color)
        settings.activities.append(a)
        return a
    }

    public func renameActivity(_ id: UUID, to name: String) {
        guard let i = settings.activities.firstIndex(where: { $0.id == id }) else { return }
        settings.activities[i].name = name
    }

    public func removeActivity(_ id: UUID) {
        settings.activities.removeAll { $0.id == id }
        if settings.lastActivityID == id { settings.lastActivityID = nil }
    }

    public func moveActivity(from source: Int, to destination: Int) {
        var list = settings.activities
        guard source != destination, list.indices.contains(source), (0...list.count).contains(destination) else { return }
        let item = list.remove(at: source)
        let target = destination > source ? destination - 1 : destination
        list.insert(item, at: min(target, list.count))
        settings.activities = list
    }

    public var daySummaries: [DaySummary] {
        HistoryAggregator.daySummaries(sessions, activities: settings.activities)
    }
}
