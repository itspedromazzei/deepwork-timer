import Foundation
import Testing
@testable import DeepworkCore

struct HistoryAggregatorTests {
    let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
        return c
    }()
    let meta = Activity(name: "Meta Ads", colorIndex: 0)
    let write = Activity(name: "Escrever", colorIndex: 1)

    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func session(_ a: Activity, _ start: Date, seconds: Int, kind: SessionKind = .focus) -> Session {
        Session(kind: kind, activityID: a.id, activityName: a.name, startedAt: start,
                endedAt: start.addingTimeInterval(TimeInterval(seconds)), plannedSeconds: seconds,
                actualSeconds: seconds, completed: true)
    }

    @Test func groupsByDayAndActivityIgnoringBreaks() {
        let sessions = [
            session(meta, date(2026, 10, 14, 9), seconds: 3000),
            session(write, date(2026, 10, 14, 11), seconds: 1500),
            session(meta, date(2026, 10, 14, 15), seconds: 600),
            session(meta, date(2026, 10, 14, 16), seconds: 600, kind: .breakTime),
            session(write, date(2026, 10, 13, 9), seconds: 1200),
        ]
        let days = HistoryAggregator.daySummaries(sessions, activities: [meta, write], calendar: cal)
        #expect(days.count == 2)
        #expect(days[0].day == cal.startOfDay(for: date(2026, 10, 14)))
        #expect(days[0].totalSeconds == 5100)
        #expect(days[0].byActivity.map(\.name) == ["Meta Ads", "Escrever"])
        #expect(days[0].byActivity[0].seconds == 3600)
        #expect(days[0].byActivity[0].colorIndex == 0)
        #expect(days[1].totalSeconds == 1200)
    }

    @Test func renamedActivityKeepsSnapshotName() {
        var renamed = meta
        renamed.name = "Anúncios"
        let sessions = [session(meta, date(2026, 10, 14), seconds: 600)]
        let days = HistoryAggregator.daySummaries(sessions, activities: [renamed], calendar: cal)
        #expect(days[0].byActivity[0].name == "Meta Ads")
        #expect(days[0].byActivity[0].colorIndex == 0)
    }

    @Test func lastDaysFillsGaps() {
        let sessions = [session(meta, date(2026, 10, 12), seconds: 600)]
        let days = HistoryAggregator.daySummaries(sessions, activities: [meta], calendar: cal)
        let series = HistoryAggregator.lastDays(5, summaries: days, today: date(2026, 10, 15), calendar: cal)
        #expect(series.count == 5)
        #expect(series.map(\.totalSeconds) == [0, 600, 0, 0, 0])
        #expect(series.last?.day == cal.startOfDay(for: date(2026, 10, 15)))
    }

    @Test func timeFormatting() {
        #expect(TimeFormatting.clock(1500) == "25:00")
        #expect(TimeFormatting.clock(3661) == "1:01:01")
        #expect(TimeFormatting.duration(8100) == "2h 15min")
        #expect(TimeFormatting.duration(3600) == "1h")
        #expect(TimeFormatting.duration(59) == "0min")
    }
}
