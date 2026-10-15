import Foundation
import Testing
@testable import DeepworkCore

struct StoreTests {
    func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dwt-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func sessionsRoundTrip() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = Store(directory: dir)
        let a = Activity(name: "Meta Ads")
        let s = Session(kind: .focus, activityID: a.id, activityName: a.name, startedAt: Date(timeIntervalSince1970: 1_700_000_000),
                        endedAt: Date(timeIntervalSince1970: 1_700_003_000), plannedSeconds: 3000, actualSeconds: 3000, completed: true)
        store.saveSessions([s])
        store.flush()
        let loaded = Store(directory: dir).loadSessions()
        #expect(loaded == [s])
    }

    @Test func settingsRoundTripAndDefaultsForMissingKeys() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = Store(directory: dir)
        var s = AppSettings()
        s.focusMinutes = 25
        s.audioMode = .binauralGamma
        store.saveSettingsNow(s)
        #expect(Store(directory: dir).loadSettings() == s)

        // Arquivo antigo com só uma chave: o resto vem dos defaults.
        try #"{"focusMinutes": 30}"#.data(using: .utf8)!.write(to: store.settingsURL)
        let partial = Store(directory: dir).loadSettings()
        #expect(partial.focusMinutes == 30)
        #expect(partial.breakMinutes == 10)
        #expect(partial.activities.count == 3)
    }

    @Test func corruptFileIsRenamedAndDefaultsUsed() throws {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = Store(directory: dir)
        try "isso não é json".data(using: .utf8)!.write(to: store.sessionsURL)
        #expect(store.loadSessions().isEmpty)
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(files.contains { $0.hasPrefix("sessions.json.corrupt-") })
        #expect(!FileManager.default.fileExists(atPath: store.sessionsURL.path))
    }
}
