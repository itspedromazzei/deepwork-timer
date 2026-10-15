import Foundation

public struct ActivityTotal: Equatable, Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let colorIndex: Int
    public let seconds: Int
}

public struct DaySummary: Equatable, Identifiable, Sendable {
    public var id: Date { day }
    public let day: Date
    public let totalSeconds: Int
    /// Ordenado do maior para o menor.
    public let byActivity: [ActivityTotal]
}

/// Funções puras sobre a lista de sessões. Só sessões de foco contam.
public enum HistoryAggregator {
    public static func daySummaries(_ sessions: [Session], activities: [Activity],
                                    calendar: Calendar = .current) -> [DaySummary] {
        let colorByName = Dictionary(activities.map { ($0.name, $0.colorIndex) }, uniquingKeysWith: { a, _ in a })
        let colorByID = Dictionary(activities.map { ($0.id, $0.colorIndex) }, uniquingKeysWith: { a, _ in a })

        var byDay: [Date: [String: (color: Int, seconds: Int)]] = [:]
        for s in sessions where s.kind == .focus && s.actualSeconds > 0 {
            let day = calendar.startOfDay(for: s.startedAt)
            let color = s.activityID.flatMap { colorByID[$0] } ?? colorByName[s.activityName] ?? 0
            var entry = byDay[day, default: [:]]
            let prev = entry[s.activityName]?.seconds ?? 0
            entry[s.activityName] = (color, prev + s.actualSeconds)
            byDay[day] = entry
        }

        return byDay.keys.sorted(by: >).map { day in
            let map = byDay[day] ?? [:]
            let totals = map.map { ActivityTotal(name: $0.key, colorIndex: $0.value.color, seconds: $0.value.seconds) }
                .sorted { $0.seconds == $1.seconds ? $0.name < $1.name : $0.seconds > $1.seconds }
            return DaySummary(day: day, totalSeconds: totals.reduce(0) { $0 + $1.seconds }, byActivity: totals)
        }
    }

    /// Série contínua dos últimos `days` dias (inclui dias sem foco, com total zero), do mais antigo ao mais recente.
    public static func lastDays(_ days: Int, summaries: [DaySummary], today: Date = Date(),
                                calendar: Calendar = .current) -> [DaySummary] {
        let byDay = Dictionary(summaries.map { ($0.day, $0) }, uniquingKeysWith: { a, _ in a })
        let start = calendar.startOfDay(for: today)
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { return nil }
            return byDay[day] ?? DaySummary(day: day, totalSeconds: 0, byActivity: [])
        }
    }

    public static func totalSeconds(on day: Date, sessions: [Session], calendar: Calendar = .current) -> Int {
        sessions.filter { $0.kind == .focus && calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.actualSeconds }
    }
}
