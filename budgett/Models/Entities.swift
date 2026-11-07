//
//  Entities.swift
//  Budgett
//
//  SwiftData schema. Amounts are stored positive; direction comes from `kind`.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Category

@Model
final class SpendCategory {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "tag.fill"
    var colorHex: String = "3B5BFF"
    var kindRaw: String = CategoryKind.expense.rawValue
    var sortIndex: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Txn.category)
    var txns: [Txn]? = []

    init(name: String,
         symbol: String = "tag.fill",
         colorHex: String = "3B5BFF",
         kind: CategoryKind = .expense,
         sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.kindRaw = kind.rawValue
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    /// The app draws monochrome; `colorHex` is kept only for stored data.
    var color: Color { .primary }
}

// MARK: - Wallet (account)

@Model
final class Wallet {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "wallet.bifold.fill"
    var colorHex: String = "3B5BFF"
    var typeRaw: String = WalletType.cash.rawValue
    var openingBalance: Decimal = 0
    var includeInNetWorth: Bool = true
    var sortIndex: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .nullify, inverse: \Txn.wallet)
    var txns: [Txn]? = []

    init(name: String,
         symbol: String = "wallet.bifold.fill",
         colorHex: String = "3B5BFF",
         type: WalletType = .cash,
         openingBalance: Decimal = 0,
         sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.typeRaw = type.rawValue
        self.openingBalance = openingBalance
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var type: WalletType {
        get { WalletType(rawValue: typeRaw) ?? .cash }
        set { typeRaw = newValue.rawValue }
    }

    /// The app draws monochrome; `colorHex` is kept only for stored data.
    var color: Color { .primary }
}

// MARK: - Transaction

@Model
final class Txn {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var kindRaw: String = TxnKind.expense.rawValue
    var date: Date = Date.now
    var title: String = ""
    var note: String = ""
    var tags: [String] = []
    var currencyCode: String = "TRY"
    var isExcluded: Bool = false        // ignored by budgets & insights
    var recurrenceID: UUID?
    var toWalletID: UUID?               // destination for transfers
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Attribute(.externalStorage) var receipt: Data?

    var category: SpendCategory?
    var wallet: Wallet?

    init(amount: Decimal,
         kind: TxnKind = .expense,
         date: Date = .now,
         title: String = "",
         note: String = "",
         category: SpendCategory? = nil,
         wallet: Wallet? = nil,
         tags: [String] = [],
         currencyCode: String = AppSettings.shared.currencyCode) {
        self.id = UUID()
        self.amount = abs(amount)
        self.kindRaw = kind.rawValue
        self.date = date
        self.title = title
        self.note = note
        self.category = category
        self.wallet = wallet
        self.tags = tags
        self.currencyCode = currencyCode
        self.createdAt = .now
        self.updatedAt = .now
    }

    var kind: TxnKind {
        get { TxnKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    /// Positive for income, negative for expenses, zero for transfers.
    var signedAmount: Decimal { amount * kind.sign }

    var displayTitle: String {
        if !title.trimmingCharacters(in: .whitespaces).isEmpty { return title }
        if let category { return category.name }
        return kind.title
    }

    var accentColor: Color { category?.color ?? kind.color }
    var glyph: String { category?.symbol ?? kind.symbol }
    var isUpcoming: Bool { date > .now }
}

// MARK: - Budget

@Model
final class BudgetPlan {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "chart.pie.fill"
    var colorHex: String = "3B5BFF"
    var amount: Decimal = 0
    var periodRaw: String = BudgetPeriod.month.rawValue
    var categoryIDs: [String] = []       // empty == every expense category
    var rollover: Bool = false
    var notifyAtPercent: Int = 80
    var sortIndex: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    init(name: String,
         symbol: String = "chart.pie.fill",
         colorHex: String = "3B5BFF",
         amount: Decimal,
         period: BudgetPeriod = .month,
         categoryIDs: [String] = [],
         sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.amount = amount
        self.periodRaw = period.rawValue
        self.categoryIDs = categoryIDs
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRaw) ?? .month }
        set { periodRaw = newValue.rawValue }
    }

    /// The app draws monochrome; `colorHex` is kept only for stored data.
    var color: Color { .primary }
    var isOverall: Bool { categoryIDs.isEmpty }
}

// MARK: - Recurring rule

@Model
final class Recurrence {
    var id: UUID = UUID()
    var title: String = ""
    var amount: Decimal = 0
    var kindRaw: String = TxnKind.expense.rawValue
    var frequencyRaw: String = RecurrenceFrequency.monthly.rawValue
    var categoryID: String?
    var walletID: String?
    var startDate: Date = Date.now
    var nextDate: Date = Date.now
    var endDate: Date?
    var autoPost: Bool = true
    var isPaused: Bool = false
    var note: String = ""
    var colorHex: String = "3B5BFF"
    var symbol: String = "arrow.trianglehead.2.clockwise.rotate.90"
    var createdAt: Date = Date.now

    init(title: String,
         amount: Decimal,
         kind: TxnKind = .expense,
         frequency: RecurrenceFrequency = .monthly,
         categoryID: String? = nil,
         walletID: String? = nil,
         startDate: Date = .now,
         autoPost: Bool = true,
         colorHex: String = "3B5BFF",
         symbol: String = "arrow.trianglehead.2.clockwise.rotate.90") {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.frequencyRaw = frequency.rawValue
        self.categoryID = categoryID
        self.walletID = walletID
        self.startDate = startDate
        self.nextDate = startDate
        self.autoPost = autoPost
        self.colorHex = colorHex
        self.symbol = symbol
        self.createdAt = .now
    }

    var kind: TxnKind {
        get { TxnKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// The app draws monochrome; `colorHex` is kept only for stored data.
    var color: Color { .primary }
    var monthlyEquivalent: Decimal { (amount * frequency.monthlyFactor).rounded(2) }
}

// MARK: - Savings goal

@Model
final class Goal {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "target"
    var colorHex: String = "16C47F"
    var target: Decimal = 0
    var saved: Decimal = 0
    var deadline: Date?
    var note: String = ""
    var sortIndex: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date.now

    init(name: String,
         symbol: String = "target",
         colorHex: String = "16C47F",
         target: Decimal,
         saved: Decimal = 0,
         deadline: Date? = nil,
         sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.target = target
        self.saved = saved
        self.deadline = deadline
        self.sortIndex = sortIndex
        self.createdAt = .now
    }

    /// The app draws monochrome; `colorHex` is kept only for stored data.
    var color: Color { .primary }

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, (saved / target).doubleValue))
    }

    var remaining: Decimal { max(0, target - saved) }

    var daysLeft: Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day
    }

    /// How much to put aside each month to land on the deadline.
    var suggestedMonthly: Decimal? {
        guard let days = daysLeft, days > 0, remaining > 0 else { return nil }
        let months = max(1, Int(ceil(Double(days) / 30.0)))
        return (remaining / Decimal(months)).rounded(0)
    }
}
