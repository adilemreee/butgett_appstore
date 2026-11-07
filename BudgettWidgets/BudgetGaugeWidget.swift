//
//  BudgetGaugeWidget.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

struct BudgetGaugeWidget: Widget {
    let kind = "BudgettBudgetGauge"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            BudgetGaugeView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Bütçe")
        .description("Bu dönem ne kadarı kaldı, günde ne kadar harcayabilirsin.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct BudgetGaugeView: View {
    var snapshot: BudgettSnapshot
    /// Lets previews and design harnesses pin a family; widgets use the environment.
    var forcedFamily: WidgetFamily?
    @Environment(\.widgetFamily) private var environmentFamily

    private var family: WidgetFamily { forcedFamily ?? environmentFamily }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            default: small
            }
        }
        .widgetURL(BudgettLink.tab("plans"))
        .budgettContainer(family, accent: snapshot.accent)
    }

    // MARK: Small

    @ViewBuilder
    private var small: some View {
        if let budget = snapshot.budget {
            VStack(spacing: 0) {
                WidgetHeader(title: budget.name, symbol: budget.symbol, tint: snapshot.budgetTint)

                ZStack {
                    WidgetArcGauge(progress: budget.progress, lineWidth: 11, tint: snapshot.budgetTint)
                    VStack(spacing: 0) {
                        WidgetAmount(text: snapshot.money(max(0, budget.remaining), cents: false),
                                     size: 21,
                                     tint: budget.isOver ? WidgetPalette.expense : .primary)
                        Text(budget.isOver ? "limit aşıldı" : "kaldı")
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: 7)
                }
                .padding(.top, 2)

                HStack(spacing: 4) {
                    Text("%\(Int(budget.progress * 100))")
                        .foregroundStyle(snapshot.budgetTint)
                    Text("·")
                    Text("\(budget.daysLeft) gün")
                    Spacer(minLength: 0)
                    Text("günde \(snapshot.money(budget.dailyAllowance, cents: false, unit: false))")
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            }
        } else {
            emptyState
        }
    }

    // MARK: Lock screen

    @ViewBuilder
    private var circular: some View {
        if let budget = snapshot.budget {
            Gauge(value: min(budget.progress, 1)) {
                Image(systemName: budget.symbol)
            } currentValueLabel: {
                Text("%\(Int(budget.progress * 100))")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Gauge(value: 0) {
                Image(systemName: "chart.pie")
            } currentValueLabel: {
                Text("–")
            }
            .gaugeStyle(.accessoryCircular)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.pie")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.secondary)
            Text("Bütçe oluştur")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            Text("Planlar sekmesinden ekle")
                .font(.system(size: 9.5, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
