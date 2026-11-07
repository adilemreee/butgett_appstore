//
//  Enums.swift
//  Budgett
//
//  Raw values are persisted as Strings so SwiftData predicates stay simple and
//  the schema survives future case additions.
//

import SwiftUI

enum TxnKind: String, CaseIterable, Identifiable, Codable {
    case expense, income, transfer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "Gider"
        case .income: "Gelir"
        case .transfer: "Transfer"
        }
    }

    var color: Color {
        switch self {
        case .expense: Palette.expense
        case .income: Palette.income
        case .transfer: Palette.transfer
        }
    }

    var symbol: String {
        switch self {
        case .expense: "arrow.down.right"
        case .income: "arrow.up.right"
        case .transfer: "arrow.left.arrow.right"
        }
    }

    /// Multiplier applied when summing into a net total.
    var sign: Decimal {
        switch self {
        case .expense: -1
        case .income: 1
        case .transfer: 0
        }
    }
}

enum CategoryKind: String, CaseIterable, Identifiable, Codable {
    case expense, income, both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "Gider"
        case .income: "Gelir"
        case .both: "Her ikisi"
        }
    }

    func matches(_ kind: TxnKind) -> Bool {
        switch self {
        case .both: return true
        case .expense: return kind == .expense
        case .income: return kind == .income
        }
    }
}

enum WalletType: String, CaseIterable, Identifiable, Codable {
    case cash, bank, card, savings, investment, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: "Nakit"
        case .bank: "Banka"
        case .card: "Kredi Kartı"
        case .savings: "Birikim"
        case .investment: "Yatırım"
        case .other: "Diğer"
        }
    }

    var symbol: String {
        switch self {
        case .cash: "banknote.fill"
        case .bank: "building.columns.fill"
        case .card: "creditcard.fill"
        case .savings: "lock.fill"
        case .investment: "chart.line.uptrend.xyaxis"
        case .other: "wallet.bifold.fill"
        }
    }
}

enum BudgetPeriod: String, CaseIterable, Identifiable, Codable {
    case week, month, year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "Haftalık"
        case .month: "Aylık"
        case .year: "Yıllık"
        }
    }

    var shortTitle: String {
        switch self {
        case .week: "bu hafta"
        case .month: "bu ay"
        case .year: "bu yıl"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    func currentInterval(_ cal: Calendar, reference: Date = .now) -> DateInterval {
        cal.dateInterval(of: component, for: reference)
            ?? DateInterval(start: reference.startOfDay, duration: 86_400)
    }
}

enum RecurrenceFrequency: String, CaseIterable, Identifiable, Codable {
    case daily, weekly, biweekly, monthly, quarterly, yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Günlük"
        case .weekly: "Haftalık"
        case .biweekly: "2 Haftada bir"
        case .monthly: "Aylık"
        case .quarterly: "3 Ayda bir"
        case .yearly: "Yıllık"
        }
    }

    func next(after date: Date, cal: Calendar) -> Date {
        switch self {
        case .daily: cal.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly: cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly: cal.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly: cal.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly: cal.date(byAdding: .month, value: 3, to: date) ?? date
        case .yearly: cal.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    /// Rough monthly equivalent, used for the subscription cost summary.
    var monthlyFactor: Decimal {
        switch self {
        case .daily: 30
        case .weekly: Decimal(string: "4.345")!
        case .biweekly: Decimal(string: "2.17")!
        case .monthly: 1
        case .quarterly: Decimal(string: "0.3333")!
        case .yearly: Decimal(string: "0.0833")!
        }
    }
}
