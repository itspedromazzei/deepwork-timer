import SwiftUI
import DeepworkCore

struct HistoryView: View {
    var model: AppModel
    @State private var expanded: Set<Date> = []

    var body: some View {
        let summaries = model.daySummaries
        VStack(alignment: .leading, spacing: 14) {
            if summaries.isEmpty {
                Text(Strings.noHistory)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.secondary)
                    .padding(.vertical, 20)
            } else {
                SectionLabel(Strings.last14Days)
                BarsView(days: HistoryAggregator.lastDays(14, summaries: summaries))
                    .frame(height: 90)
                SectionLabel("Por dia")
                ForEach(summaries) { day in
                    dayRow(day, isFirst: day.id == summaries.first?.id)
                }
            }
        }
    }

    private func dayRow(_ day: DaySummary, isFirst: Bool) -> some View {
        let isOpen = expanded.contains(day.day) || (isFirst && expanded.isEmpty)
        return VStack(alignment: .leading, spacing: 6) {
            Button {
                if isOpen {
                    expanded.remove(day.day)
                    if isFirst && expanded.isEmpty { expanded.insert(Date.distantPast) }
                } else {
                    expanded.insert(day.day)
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isOpen ? 90 : 0))
                        .foregroundStyle(Theme.faint)
                    Text(TimeFormatting.dayLabel(day.day))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text(TimeFormatting.duration(day.totalSeconds))
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.focus)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                ForEach(day.byActivity) { a in
                    HStack(spacing: 8) {
                        Circle().fill(Theme.activityColor(a.colorIndex)).frame(width: 7, height: 7)
                        Text(a.name.isEmpty ? "Sem atividade" : a.name)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondary)
                        Spacer()
                        Text(TimeFormatting.duration(a.seconds))
                            .font(.system(size: 12))
                            .monospacedDigit()
                            .foregroundStyle(Theme.secondary)
                    }
                    .padding(.leading, 18)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Barras empilhadas por atividade, uma por dia.
struct BarsView: View {
    let days: [DaySummary]

    var body: some View {
        let maxSeconds = max(1, days.map(\.totalSeconds).max() ?? 1)
        GeometryReader { geo in
            let barHeight = geo.size.height - 16
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days) { day in
                    VStack(spacing: 4) {
                        VStack(spacing: 1) {
                            Spacer(minLength: 0)
                            ForEach(day.byActivity.reversed()) { a in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.activityColor(a.colorIndex))
                                    .frame(height: max(2, barHeight * CGFloat(a.seconds) / CGFloat(maxSeconds)))
                            }
                            if day.totalSeconds == 0 {
                                RoundedRectangle(cornerRadius: 2).fill(Theme.track).frame(height: 2)
                            }
                        }
                        .frame(height: barHeight)
                        Text(shortDay(day.day))
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.faint)
                    }
                    .frame(maxWidth: .infinity)
                    .help("\(TimeFormatting.dayLabel(day.day)): \(TimeFormatting.duration(day.totalSeconds))")
                }
            }
        }
    }

    private func shortDay(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "d"
        return f.string(from: d)
    }
}
