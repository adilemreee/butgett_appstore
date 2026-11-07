//
//  InsightsEngine.swift
//  Budgett
//
//  Pure aggregation over transactions. Everything the charts and the smart
//  summary cards need is derived here so views stay dumb.
//

import Foundation
import SwiftUI

struct PeriodStats {
    var income: Decimal = 0
    var expense: Decimal = 0
    var count: Int = 0
    var interval: DateInterval = DateInterval(start: .now, duration: 0)

    var net: Decimal { income - expense }

    var perDay: Decimal {
        let days = Decimal(interval.elapsedDays())
        guard days > 0 else { return expense }
        return (expense / days).rounded(2)
    }

    var isEmpty: Bool { count == 0 }
}

struct CategorySlice: Identifiable, Equatable {
    var id: String
    var name: String
    var colorHex: String
    var symbol: String
    var total: Decimal
    var share: Double
    var count: Int

    var color: Color { Color(hex: colorHex) }
}

struct TimeBucket: Identifiable, Equatable {
    var id: Date { start }
    var start: Date
    var label: String
    var expense: Decimal
    var income: Decimal
}

enum InsightsEngine {

    // MARK: - Filtering

    static func inRange(_ txns: [Txn], _ interval: DateInterval) -> [Txn] {
        txns.filter { !$0.isExcluded && interval.contains($0.date) }
    }

    // MARK: - Totals

    static func stats(_ txns: [Txn], interval: DateInterval) -> PeriodStats {
        var stats = PeriodStats(interval: interval)
        for txn in txns where !txn.isExcluded {
            switch txn.kind {
            case .expense: stats.expense += txn.amount
            case .income: stats.income += txn.amount
            case .transfer: continue
            }
            stats.count += 1
        }
        return stats
    }

    // MARK: - Category breakdown

    static func slices(_ txns: [Txn], kind: TxnKind) -> [CategorySlice] {
        let filtered = txns.filter { $0.kind == kind && !$0.isExcluded }
        let total = filtered.reduce(Decimal(0)) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var buckets: [String: CategorySlice] = [:]
        for txn in filtered {
            let key = txn.category?.id.uuidString ?? "uncategorised"
            var slice = buckets[key] ?? CategorySlice(
                id: key,
                name: txn.category?.name ?? "Kategorisiz",
                colorHex: txn.category?.colorHex ?? "7D8CA3",
                symbol: txn.category?.symbol ?? "questionmark.circle.fill",
                total: 0, share: 0, count: 0
            )
            slice.total += txn.amount
            slice.count += 1
            buckets[key] = slice
        }

        return buckets.values
            .map { slice in
                var copy = slice
                copy.share = (slice.total / total).doubleValue
                return copy
            }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Time series

    static func buckets(_ txns: [Txn], cursor: PeriodCursor, cal: Calendar) -> [TimeBucket] {
        let interval = cursor.interval(cal)
        let component = cursor.period.bucket
        let (start, end): (Date, Date) = {
            if cursor.period == .all {
                let dates = txns.map(\.date).sorted()
                guard let first = dates.first, let last = dates.last else { return (Date.now, Date.now) }
                return (first, last)
            }
            return (interval.start, interval.end)
        }()

        var slots: [Date] = []
        var cursorDate = cal.dateInterval(of: component, for: start)?.start ?? start
        let limit = end
        var guardCount = 0
        while cursorDate < limit && guardCount < 400 {
            slots.append(cursorDate)
            guard let next = cal.date(byAdding: component, value: 1, to: cursorDate) else { break }
            cursorDate = next
            guardCount += 1
        }
        if slots.isEmpty { slots = [start] }

        var expense: [Date: Decimal] = [:]
        var income: [Date: Decimal] = [:]
        for txn in txns where !txn.isExcluded {
            guard let slot = cal.dateInterval(of: component, for: txn.date)?.start else { continue }
            switch txn.kind {
            case .expense: expense[slot, default: 0] += txn.amount
            case .income: income[slot, default: 0] += txn.amount
            case .transfer: break
            }
        }

        return slots.map { slot in
            TimeBucket(start: slot,
                       label: label(for: slot, period: cursor.period, cal: cal),
                       expense: expense[slot] ?? 0,
                       income: income[slot] ?? 0)
        }
    }

    private static func label(for date: Date, period: Period, cal: Calendar) -> String {
        switch period {
        case .day:
            return date.formatted(.dateTime.hour())
        case .week:
            return String(date.formatted(.dateTime.weekday(.narrow)))
        case .month:
            return date.formatted(.dateTime.day())
        case .year, .all:
            return String(date.formatted(.dateTime.month(.narrow)))
        }
    }

    /// Expense totals keyed by day — powers the calendar heat map.
    static func dailyTotals(_ txns: [Txn], cal: Calendar) -> [Date: Decimal] {
        var result: [Date: Decimal] = [:]
        for txn in txns where txn.kind == .expense && !txn.isExcluded {
            let day = cal.startOfDay(for: txn.date)
            result[day, default: 0] += txn.amount
        }
        return result
    }

    // MARK: - Streaks

    /// Consecutive days up to today without a single expense.
    static func noSpendStreak(_ txns: [Txn], cal: Calendar) -> Int {
        let spendDays = Set(txns.filter { $0.kind == .expense && !$0.isExcluded }
            .map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var day = cal.startOfDay(for: .now)
        while !spendDays.contains(day) && streak < 365 {
            streak += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}
