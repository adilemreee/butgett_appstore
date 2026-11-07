//
//  UpcomingBillsWidget.swift
//  BudgettWidgets
//

import WidgetKit
import SwiftUI

struct UpcomingBillsWidget: Widget {
    let kind = "BudgettBills"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SnapshotProvider()) { entry in
            UpcomingBillsView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Yaklaşan ödemeler")
        .description("Sıradaki abonelik ve düzenli ödemeler.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct UpcomingBillsView: View {
    var snapshot: BudgettSnapshot
    /// Lets previews and design harnesses pin a family; widgets use the environment.
    var forcedFamily: WidgetFamily?
    @Environment(\.widgetFamily) private var environmentFamily

    private var family: WidgetFamily { forcedFamily ?? environmentFamily }

    private var total: Decimal {
        snapshot.bills.reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular: rectangular
            case .systemMedium: medium
            default: small
            }
        }
        .widgetURL(BudgettLink.tab("plans"))
        .budgettContainer(family, accent: snapshot.accent)
    }

    @ViewBuilder
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(title: "Yaklaşan", symbol: "calendar.badge.clock", tint: snapshot.accent)

            if let next = snapshot.bills.first {
                Spacer(minLength: 4)
                WidgetGlyph(symbol: next.symbol, color: .primary, size: 26)
                Text(next.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .padding(.top, 5)
                WidgetAmount(text: snapshot.money(next.amount), size: 17)
                Text(next.relativeTitle.lowercased() + " · " + next.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if snapshot.bills.count > 1 {
                    Text("+\(snapshot.bills.count - 1) ödeme daha")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                }
            } else {
                Spacer(minLength: 0)
                Text("Sırada ödeme yok")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                WidgetHeader(title: "Yaklaşan ödemeler", symbol: "calendar.badge.clock", tint: snapshot.accent)
                if !snapshot.bills.isEmpty {
                    Text(snapshot.money(total, cents: false))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            if snapshot.bills.isEmpty {
                Spacer(minLength: 0)
                Text("Tanımlı düzenli ödemen yok.")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                ForEach(snapshot.bills.prefix(3)) { bill in
                    HStack(spacing: 8) {
                        WidgetGlyph(symbol: bill.symbol, color: .primary, size: 22)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(bill.title)
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                            Text("\(bill.relativeTitle) · \(bill.date.formatted(.dateTime.day().month(.abbreviated)))")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 6)
                        Text(snapshot.money(bill.amount))
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if let next = snapshot.bills.first {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 9, weight: .bold))
                    Text(next.relativeTitle.uppercased())
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.secondary)
                Text(next.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(snapshot.money(next.amount))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Sırada ödeme yok")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }
}
