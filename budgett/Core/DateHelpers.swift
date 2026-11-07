//
//  DateHelpers.swift
//  Budgett
//
//  Period windowing used by the transaction list, insights and budgets.
//

import Foundation

enum Period: String, CaseIterable, Identifiable, Codable {
    case day, week, month, year, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: "Gün"
        case .week: "Hafta"
        case .month: "Ay"
        case .year: "Yıl"
        case .all: "Tümü"
        }
    }

    var perLabel: String {
        switch self {
        case .day: "bugün"
        case .week: "bu hafta"
        case .month: "bu ay"
        case .year: "bu yıl"
        case .all: "toplam"
        }
    }

    var component: Calendar.Component? {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        case .all: nil
        }
    }

    /// Granularity used when bucketing this period into chart columns.
    var bucket: Calendar.Component {
        switch self {
        case .day: .hour
        case .week: .day
        case .month: .day
        case .year: .month
        case .all: .month
        }
    }
}

struct PeriodCursor: Equatable {
    var period: Period
    var anchor: Date

    init(period: Period = .month, anchor: Date = .now) {
        self.period = period
        self.anchor = anchor
    }

    func interval(_ cal: Calendar) -> DateInterval {
        guard let component = period.component else {
            return DateInterval(start: .distantPast, end: .distantFuture)
        }
        return cal.dateInterval(of: component, for: anchor)
            ?? DateInterval(start: cal.startOfDay(for: anchor), duration: 86_400)
    }

    /// The equivalent window one step in the past — used for trend comparisons.
    func previousInterval(_ cal: Calendar) -> DateInterval {
        guard let component = period.component,
              let shifted = cal.date(byAdding: component, value: -1, to: anchor) else {
            return DateInterval(start: .distantPast, end: .distantPast)
        }
        return PeriodCursor(period: period, anchor: shifted).interval(cal)
    }

    mutating func step(_ direction: Int, cal: Calendar) {
        guard let component = period.component,
              let next = cal.date(byAdding: component, value: direction, to: anchor) else { return }
        anchor = next
    }

    func canStepForward(_ cal: Calendar) -> Bool {
        guard period != .all else { return false }
        return interval(cal).end < Date.now
    }

    var isCurrent: Bool {
        guard let component = period.component else { return true }
        return Calendar.current.isDate(anchor, equalTo: .now, toGranularity: component)
    }

    func title(_ cal: Calendar) -> String {
        switch period {
        case .day:
            if cal.isDateInToday(anchor) { return "Bugün" }
            if cal.isDateInYesterday(anchor) { return "Dün" }
            return anchor.formatted(.dateTime.day().month(.abbreviated).locale(.current))
        case .week:
            let range = interval(cal)
            let end = cal.date(byAdding: .day, value: -1, to: range.end) ?? range.end
            let a = range.start.formatted(.dateTime.day().month(.abbreviated))
            let b = end.formatted(.dateTime.day().month(.abbreviated))
            return "\(a) – \(b)"
        case .month:
            if cal.isDate(anchor, equalTo: .now, toGranularity: .year) {
                return anchor.formatted(.dateTime.month(.wide))
            }
            return anchor.formatted(.dateTime.month(.wide).year())
        case .year:
            return anchor.formatted(.dateTime.year())
        case .all:
            return "Tüm zamanlar"
        }
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func dayTitle(_ cal: Calendar = .current) -> String {
        if cal.isDateInToday(self) { return "BUGÜN" }
        if cal.isDateInYesterday(self) { return "DÜN" }
        if cal.isDateInTomorrow(self) { return "YARIN" }
        let sameYear = cal.isDate(self, equalTo: .now, toGranularity: .year)
        let style: Date.FormatStyle = sameYear
            ? .dateTime.weekday(.abbreviated).day().month(.abbreviated)
            : .dateTime.day().month(.abbreviated).year()
        return formatted(style).uppercased()
    }

    var timeTitle: String { formatted(.dateTime.hour().minute()) }
}

extension DateInterval {
    /// Number of whole days in the interval, at least 1.
    func dayCount(_ cal: Calendar = .current) -> Int {
        guard start > .distantPast, end < .distantFuture else { return 1 }
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 1
        return max(days, 1)
    }

    /// Days elapsed so far (for pace calculations), clamped to the interval.
    func elapsedDays(_ cal: Calendar = .current) -> Int {
        guard start > .distantPast else { return 1 }
        let cap = min(Date.now, end)
        guard cap > start else { return 1 }
        let days = (cal.dateComponents([.day], from: start, to: cap).day ?? 0) + 1
        return max(1, min(days, dayCount(cal)))
    }
}
