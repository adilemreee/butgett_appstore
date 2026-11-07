//
//  WidgetPublisher.swift
//  Budgett
//
//  Builds the shared snapshot the widgets render from and pokes WidgetKit.
//

import Foundation
import SwiftData
import WidgetKit

enum WidgetPublisher {

    static func publish(context: ModelContext, settings: AppSettings) {
        let cal = settings.calendar
        let txns = ((try? context.fetch(FetchDescriptor<Txn>())) ?? [])
            .filter { !$0.isExcluded }
        let wallets = (try? context.fetch(FetchDescriptor<Wallet>())) ?? []
        let plans = (try? context.fetch(FetchDescriptor<BudgetPlan>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<SpendCategory>())) ?? []
        let rules = (try? context.fetch(FetchDescriptor<Recurrence>())) ?? []

        var snapshot = BudgettSnapshot()
        snapshot.updatedAt = .now
        snapshot.currencyCode = settings.currencyCode
        snapshot.showCents = settings.showCents
        snapshot.privacyMode = settings.privacyMode
        snapshot.trackIncome = settings.trackIncome
        snapshot.accentHex = settings.accent.hex

        let posted = txns.filter { !$0.isUpcoming }

        let dayInterval = PeriodCursor(period: .day, anchor: .now).interval(cal)
        let weekInterval = PeriodCursor(period: .week, anchor: .now).interval(cal)
        let monthInterval = PeriodCursor(period: .month, anchor: .now).interval(cal)

        let dayStats = InsightsEngine.stats(posted.filter { dayInterval.contains($0.date) }, interval: dayInterval)
        let weekStats = InsightsEngine.stats(posted.filter { weekInterval.contains($0.date) }, interval: weekInterval)
        let monthTxns = posted.filter { monthInterval.contains($0.date) }
        let monthStats = InsightsEngine.stats(monthTxns, interval: monthInterval)

        snapshot.todaySpent = dayStats.expense
        snapshot.weekSpent = weekStats.expense
        snapshot.weekIncome = weekStats.income
        snapshot.monthSpent = monthStats.expense
        snapshot.monthIncome = monthStats.income
        snapshot.dailyAverage = monthStats.perDay
        snapshot.netWorth = NetWorth.total(wallets: wallets, txns: txns)
        snapshot.noSpendStreak = InsightsEngine.noSpendStreak(posted, cal: cal)

        // Last seven days, oldest first.
        let totals = InsightsEngine.dailyTotals(posted, cal: cal)
        snapshot.days = (0..<7).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else { return nil }
            return BudgettSnapshot.Day(date: day, amount: totals[day] ?? 0)
        }

        snapshot.categories = InsightsEngine.slices(monthTxns, kind: .expense)
            .prefix(5)
            .map { slice in
                BudgettSnapshot.Slice(name: slice.name, colorHex: slice.colorHex,
                                      symbol: slice.symbol, amount: slice.total, share: slice.share)
            }

        snapshot.recent = posted
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { txn in
                BudgettSnapshot.Entry(title: txn.displayTitle,
                                      amount: txn.amount,
                                      isIncome: txn.kind == .income,
                                      colorHex: txn.category?.colorHex ?? (txn.kind == .income ? "16C47F" : "7D8CA3"),
                                      symbol: txn.glyph,
                                      date: txn.date)
            }

        if let plan = plans.first(where: { !$0.isArchived && $0.isOverall })
            ?? plans.filter({ !$0.isArchived }).sorted(by: { $0.sortIndex < $1.sortIndex }).first {
            let status = BudgetEngine.status(for: plan, txns: txns, categories: categories, cal: cal)
            snapshot.budget = BudgettSnapshot.Budget(
                name: plan.name,
                symbol: plan.symbol,
                colorHex: plan.colorHex,
                limit: status.limit,
                spent: status.spent,
                periodLabel: plan.period.shortTitle,
                daysLeft: status.daysLeft,
                dailyAllowance: status.dailyAllowance
            )
        }

        snapshot.bills = RecurringEngine.upcoming(rules, within: 30, cal: cal)
            .prefix(4)
            .map { bill in
                BudgettSnapshot.Bill(title: bill.rule.title,
                                     amount: bill.rule.amount,
                                     date: bill.date,
                                     colorHex: bill.rule.colorHex,
                                     symbol: bill.rule.symbol)
            }

        guard SharedStore.save(snapshot) else { return }
        WatchSyncService.shared.push(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
