//
//  BudgetEngine.swift
//  Budgett
//

import Foundation
import SwiftUI

struct BudgetStatus: Identifiable {
    var plan: BudgetPlan
    var interval: DateInterval
    var limit: Decimal
    var spent: Decimal
    var rolledOver: Decimal
    var categories: [SpendCategory]

    var id: UUID { plan.id }
    var remaining: Decimal { limit - spent }
    var isOver: Bool { spent > limit }

    var progress: Double {
        guard limit > 0 else { return 0 }
        return max(0, (spent / limit).doubleValue)
    }

    var daysLeft: Int {
        let days = Calendar.current.dateComponents([.day], from: .now, to: interval.end).day ?? 0
        return max(0, days)
    }

    /// What you can spend per remaining day and still land on target.
    var dailyAllowance: Decimal {
        let days = Decimal(max(1, daysLeft))
        guard remaining > 0 else { return 0 }
        return (remaining / days).rounded(0)
    }

    /// Where the current pace lands at the end of the period.
    var projected: Decimal {
        let elapsed = Decimal(interval.elapsedDays())
        let total = Decimal(interval.dayCount())
        guard elapsed > 0 else { return spent }
        return ((spent / elapsed) * total).rounded(0)
    }

    var isOnTrack: Bool { projected <= limit }

    var statusColor: Color {
        if isOver { return Palette.expense }
        if progress > 0.85 || !isOnTrack { return Palette.warning }
        return Palette.income
    }
}

enum BudgetEngine {

    static func matches(_ txn: Txn, plan: BudgetPlan) -> Bool {
        guard txn.kind == .expense, !txn.isExcluded else { return false }
        if plan.categoryIDs.isEmpty { return true }
        guard let id = txn.category?.id.uuidString else { return false }
        return plan.categoryIDs.contains(id)
    }

    static func status(for plan: BudgetPlan,
                       txns: [Txn],
                       categories: [SpendCategory],
                       cal: Calendar,
                       reference: Date = .now) -> BudgetStatus {
        let interval = plan.period.currentInterval(cal, reference: reference)
        let relevant = txns.filter { matches($0, plan: plan) }
        let spent = relevant
            .filter { interval.contains($0.date) }
            .reduce(Decimal(0)) { $0 + $1.amount }

        var rolled: Decimal = 0
        if plan.rollover,
           let previousAnchor = cal.date(byAdding: plan.period.component, value: -1, to: reference) {
            let previous = plan.period.currentInterval(cal, reference: previousAnchor)
            let previousSpent = relevant
                .filter { previous.contains($0.date) }
                .reduce(Decimal(0)) { $0 + $1.amount }
            rolled = max(0, plan.amount - previousSpent)
        }

        let planCategories = plan.categoryIDs.isEmpty
            ? []
            : categories.filter { plan.categoryIDs.contains($0.id.uuidString) }

        return BudgetStatus(plan: plan,
                            interval: interval,
                            limit: plan.amount + rolled,
                            spent: spent,
                            rolledOver: rolled,
                            categories: planCategories)
    }

    static func statuses(plans: [BudgetPlan],
                         txns: [Txn],
                         categories: [SpendCategory],
                         cal: Calendar) -> [BudgetStatus] {
        plans
            .filter { !$0.isArchived }
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { status(for: $0, txns: txns, categories: categories, cal: cal) }
    }

    /// Budgets whose alert threshold was crossed by the freshly added transaction.
    static func triggeredAlerts(for txn: Txn,
                                plans: [BudgetPlan],
                                txns: [Txn],
                                categories: [SpendCategory],
                                cal: Calendar) -> [BudgetStatus] {
        plans
            .filter { !$0.isArchived && $0.notifyAtPercent > 0 && matches(txn, plan: $0) }
            .map { status(for: $0, txns: txns, categories: categories, cal: cal) }
            .filter { $0.progress * 100 >= Double($0.plan.notifyAtPercent) }
    }
}
