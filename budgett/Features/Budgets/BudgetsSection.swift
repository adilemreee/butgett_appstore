//
//  BudgetsSection.swift
//  Budgett
//

import SwiftUI
import SwiftData

struct BudgetsSection: View {
    @Binding var showCreate: Bool

    @Environment(\.settings) private var settings
    @Environment(\.modelContext) private var context

    @Query(sort: \BudgetPlan.sortIndex) private var plans: [BudgetPlan]
    @Query private var txns: [Txn]
    @Query(sort: \SpendCategory.sortIndex) private var categories: [SpendCategory]

    @State private var editing: BudgetPlan?
    @State private var detail: BudgetStatus?

    private var statuses: [BudgetStatus] {
        BudgetEngine.statuses(plans: plans, txns: txns, categories: categories, cal: settings.calendar)
    }

    private var overall: BudgetStatus? {
        statuses.first { $0.plan.isOverall }
    }

    private var scoped: [BudgetStatus] {
        statuses.filter { !$0.plan.isOverall }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 14) {
            if statuses.isEmpty {
                EmptyStateView(symbol: "chart.pie",
                               title: "Henüz bütçe yok",
                               message: "Bir limit belirle, Budgett kalan günlük harcama payını hesaplasın.",
                               actionTitle: "Bütçe oluştur") { showCreate = true }
                    .glassCard()
                    .padding(.horizontal, Metrics.hPadding)
            } else {
                if let overall {
                    OverallGaugeCard(status: overall)
                        .padding(.horizontal, Metrics.hPadding)
                        .onTapGesture { detail = overall }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(scoped) { status in
                        BudgetCard(status: status)
                            .onTapGesture { detail = status }
                            .contextMenu {
                                Button("Düzenle", systemImage: "pencil") { editing = status.plan }
                                Button("Sil", systemImage: "trash", role: .destructive) {
                                    context.delete(status.plan)
                                }
                            }
                    }
                }
                .padding(.horizontal, Metrics.hPadding)
            }
        }
        .sheet(isPresented: $showCreate) { BudgetEditor(plan: nil) }
        .sheet(item: $editing) { plan in BudgetEditor(plan: plan) }
        .sheet(item: $detail) { status in BudgetDetailSheet(planID: status.plan.id) }
    }
}

// MARK: - Overall gauge

struct OverallGaugeCard: View {
    var status: BudgetStatus
    @Environment(\.settings) private var settings

    private let gaugeSize: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            Text("%\(Int(status.progress * 100)) HARCANDI")
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)

            ZStack {
                ArcGauge(progress: status.progress, lineWidth: 14, tint: .primary)
                    .frame(width: gaugeSize, height: gaugeSize)

                VStack(spacing: 3) {
                    AmountLabel(amount: max(0, status.remaining), size: 26)
                        .frame(maxWidth: gaugeSize * 0.70)
                    Text(status.isOver ? "limit aşıldı" : "kaldı · \(status.plan.period.shortTitle)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .offset(y: gaugeSize * 0.055)
            }
            .padding(.bottom, -gaugeSize * 0.15)

            HStack {
                Text(Money.string(status.spent, settings: settings))
                Spacer(minLength: 12)
                Text(Money.string(status.limit, settings: settings))
            }
            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 6)

            Text("günde \(Money.string(status.dailyAllowance, settings: settings)) · \(status.daysLeft) gün kaldı")
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 14)
        }
        .padding(16)
        .glassCard()
    }

}

// MARK: - Budget card

struct BudgetCard: View {
    var status: BudgetStatus
    @Environment(\.settings) private var settings

    private var paceMarker: Double {
        let total = Double(status.interval.dayCount())
        guard total > 0 else { return 0 }
        return Double(status.interval.elapsedDays()) / total
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: status.plan.symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(status.plan.color)
                    .frame(width: 26, height: 26)
                    .background(status.plan.color.opacity(0.16), in: Circle())
                Text(status.plan.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text("\(status.daysLeft) gün kaldı")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)

            Text("%\(Int(status.progress * 100)) HARCANDI")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(status.statusColor)

            AmountLabel(amount: max(0, status.remaining), size: 20,
                        tint: status.isOver ? Palette.expense : .primary)

            Text(status.isOver ? "limit aşıldı" : "kaldı · \(status.plan.period.shortTitle)")
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            BudgetBar(progress: status.progress, tint: status.statusColor, marker: paceMarker, height: 9)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(radius: 24)
    }
}
