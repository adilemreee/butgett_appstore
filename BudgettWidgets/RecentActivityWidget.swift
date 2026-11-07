//
//  RecentActivityWidget.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

struct RecentActivityWidget: Widget {
    let kind = "BudgettRecent"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            RecentActivityView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Son hareketler")
        .description("Net durum ve en son işlemlerin.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct RecentActivityView: View {
    var snapshot: BudgettSnapshot
    /// Lets previews and design harnesses pin a family; widgets use the environment.
    var forcedFamily: WidgetFamily?
    @Environment(\.widgetFamily) private var environmentFamily

    private var family: WidgetFamily { forcedFamily ?? environmentFamily }

    private var rowCount: Int { family == .systemLarge ? 5 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(snapshot.trackIncome ? "NET · BU AY" : "HARCAMA · BU AY")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)
                    WidgetAmount(
                        text: snapshot.trackIncome
                            ? snapshot.money(snapshot.monthNet, cents: false, signed: true)
                            : snapshot.money(snapshot.monthSpent, cents: false),
                        size: 24,
                        tint: snapshot.trackIncome && snapshot.monthNet >= 0 ? WidgetPalette.income : .primary
                    )
                }

                Spacer(minLength: 8)

                Link(destination: BudgettLink.newExpense) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(width: 32, height: 32)
                        .background(Color.primary, in: Circle())
                }
            }

            if snapshot.recent.isEmpty {
                Spacer(minLength: 0)
                Text("Henüz işlem yok")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(snapshot.recent.prefix(rowCount).enumerated()), id: \.element.id) { index, item in
                        row(item)
                        if index < min(snapshot.recent.count, rowCount) - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(BudgettLink.tab("flow"))
        .budgettContainer(family, accent: snapshot.accent)
    }

    private func row(_ item: BudgettSnapshot.Entry) -> some View {
        HStack(spacing: 8) {
            WidgetGlyph(symbol: item.symbol, color: .primary, size: 22)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.title)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(item.date.formatted(.dateTime.day().month(.abbreviated).hour().minute()))
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Text(snapshot.money(item.isIncome ? item.amount : -item.amount, signed: true))
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(item.isIncome ? WidgetPalette.income : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 4)
    }
}
