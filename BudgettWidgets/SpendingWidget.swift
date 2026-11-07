//
//  SpendingWidget.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

struct SpendingWidget: Widget {
    let kind = "BudgettSpending"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            SpendingView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Harcama")
        .description("Son yedi günün ve bu haftanın özeti.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct SpendingView: View {
    var snapshot: BudgettSnapshot
    /// Lets previews and design harnesses pin a family; widgets use the environment.
    var forcedFamily: WidgetFamily?
    @Environment(\.widgetFamily) private var environmentFamily

    private var family: WidgetFamily { forcedFamily ?? environmentFamily }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("Bu hafta \(snapshot.money(snapshot.weekSpent, cents: false))")
            case .accessoryRectangular:
                rectangular
            case .systemMedium:
                medium
            default:
                small
            }
        }
        .widgetURL(BudgettLink.tab("insights"))
        .budgettContainer(family, accent: snapshot.accent)
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(title: "Bu hafta", symbol: "chart.bar.fill", tint: snapshot.accent)

            WidgetAmount(text: snapshot.money(snapshot.weekSpent, cents: false), size: 24)
                .padding(.top, 4)

            Text("günde ort. \(snapshot.money(snapshot.dailyAverage, cents: false))")
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer(minLength: 4)

            WidgetBars(days: snapshot.days, tint: snapshot.accent)
                .frame(height: 52)
        }
    }

    // MARK: Medium

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(title: "Bu hafta", symbol: "chart.bar.fill", tint: snapshot.accent)

                WidgetAmount(text: snapshot.money(snapshot.weekSpent, cents: false), size: 26)
                    .padding(.top, 4)

                if snapshot.trackIncome {
                    HStack(spacing: 4) {
                        Image(systemName: snapshot.weekNet >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text("net \(snapshot.money(snapshot.weekNet, cents: false, signed: true))")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(snapshot.weekNet >= 0 ? WidgetPalette.income : WidgetPalette.expense)
                }

                Spacer(minLength: 6)

                WidgetBars(days: snapshot.days, tint: snapshot.accent)
                    .frame(height: 56)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("BU AY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.tertiary)

                ForEach(Array(snapshot.categories.prefix(4).enumerated()), id: \.element.id) { index, slice in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(WidgetPalette.shade(index))
                            .frame(width: 7, height: 7)
                        Text(slice.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text("%\(Int(slice.share * 100))")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                if snapshot.categories.isEmpty {
                    Text("Bu ay kayıt yok")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Link(destination: BudgettLink.newExpense) {
                    Label("Ekle", systemImage: "plus")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                        .foregroundStyle(Color.primary)
                }
            }
            .frame(width: 132)
        }
    }

    // MARK: Lock screen

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("BU HAFTA")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.secondary)

            Text(snapshot.money(snapshot.weekSpent, cents: false))
                .font(.system(size: 19, weight: .bold, design: .rounded))

            if let budget = snapshot.budget {
                Text("\(budget.name): \(snapshot.money(max(0, budget.remaining), cents: false)) kaldı")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("günde ort. \(snapshot.money(snapshot.dailyAverage, cents: false))")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
