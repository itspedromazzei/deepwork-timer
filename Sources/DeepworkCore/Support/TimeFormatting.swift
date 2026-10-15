import Foundation

public enum TimeFormatting {
    /// "25:00" ou "1:05:00" acima de uma hora.
    public static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    /// "2h 15min", "45min", "0min".
    public static func duration(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)min" }
        if h > 0 { return "\(h)h" }
        return "\(m)min"
    }

    /// "Hoje", "Ontem" ou "ter, 14 out".
    public static func dayLabel(_ day: Date, relativeTo today: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: today) { return "Hoje" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Ontem"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.calendar = calendar
        f.dateFormat = "EEE, d MMM"
        return f.string(from: day).replacingOccurrences(of: ".", with: "")
    }
}
