//
//  RecurringEngine.swift
//  Budgett
//

import Foundation
import SwiftData

struct UpcomingBill: Identifiable {
    var id: UUID { rule.id }
    var rule: Recurrence
    var date: Date

    var daysAway: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now.startOfDay, to: date.startOfDay).day ?? 0)
    }

    var relativeTitle: String {
        switch daysAway {
        case 0: "Bugün"
        case 1: "Yarın"
        default: "\(daysAway) gün sonra"
        }
    }
}

enum RecurringEngine {

    /// Creates transactions for every rule whose due date has passed.
    /// Returns how many transactions were posted.
    @discardableResult
    static func postDue(context: ModelContext, cal: Calendar, now: Date = .now) -> Int {
        let rules = (try? context.fetch(FetchDescriptor<Recurrence>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<SpendCategory>())) ?? []
        let wallets = (try? context.fetch(FetchDescriptor<Wallet>())) ?? []
        var posted = 0

        for rule in rules where !rule.isPaused {
            var guardCount = 0
            while rule.nextDate <= now && guardCount < 60 {
                if let end = rule.endDate, rule.nextDate > end { break }
                if rule.autoPost {
                    let txn = Txn(amount: rule.amount,
                                  kind: rule.kind,
                                  date: rule.nextDate,
                                  title: rule.title,
                                  note: rule.note,
                                  category: categories.first { $0.id.uuidString == rule.categoryID },
                                  wallet: wallets.first { $0.id.uuidString == rule.walletID })
                    txn.recurrenceID = rule.id
                    context.insert(txn)
                    posted += 1
                }
                rule.nextDate = rule.frequency.next(after: rule.nextDate, cal: cal)
                guardCount += 1
            }
        }

        if posted > 0 { try? context.save() }
        return posted
    }

    static func upcoming(_ rules: [Recurrence], within days: Int = 30, cal: Calendar) -> [UpcomingBill] {
        let horizon = cal.date(byAdding: .day, value: days, to: .now) ?? .now
        return rules
            .filter { !$0.isPaused && $0.nextDate <= horizon }
            .filter { rule in
                if let end = rule.endDate { return rule.nextDate <= end }
                return true
            }
            .sorted { $0.nextDate < $1.nextDate }
            .map { UpcomingBill(rule: $0, date: $0.nextDate) }
    }

    static func monthlyLoad(_ rules: [Recurrence], kind: TxnKind) -> Decimal {
        rules
            .filter { !$0.isPaused && $0.kind == kind }
            .reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
    }
}
