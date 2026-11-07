//
//  TxnRow.swift
//  Budgett
//

import SwiftUI

struct TxnRow: View {
    var txn: Txn
    var showDate: Bool = false

    @Environment(\.settings) private var settings

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                CategoryBadge(symbol: txn.glyph, color: txn.accentColor, size: 42)
                if txn.recurrenceID != nil {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(.systemBackground))
                        .padding(3)
                        .background(Color.secondary, in: Circle())
                        .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: 1.5))
                        .offset(x: 3, y: 3)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.displayTitle)
                    .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(showDate
                         ? txn.date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
                         : txn.date.timeTitle)
                    if let wallet = txn.wallet {
                        Text("·")
                        Text(wallet.name).lineLimit(1)
                    }
                    if txn.isExcluded {
                        Image(systemName: "eye.slash.fill")
                    }
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                AmountLabel(amount: displayAmount,
                            sign: txn.kind == .transfer ? .none : .always,
                            size: 15.5,
                            tint: amountTint,
                            unitOpacity: 0.55)
                if !txn.tags.isEmpty {
                    Text(txn.tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 7)
        .opacity(txn.isUpcoming ? 0.55 : 1)
    }

    private var displayAmount: Decimal {
        txn.kind == .expense ? -txn.amount : txn.amount
    }

    private var amountTint: Color {
        switch txn.kind {
        case .income: Palette.income
        case .expense: .primary
        case .transfer: Palette.transfer
        }
    }
}

// MARK: - Upcoming row

struct UpcomingRow: View {
    var bill: UpcomingBill

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(symbol: bill.rule.symbol, color: bill.rule.color, size: 40, filled: false)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(3)
                        .background(.thickMaterial, in: Circle())
                        .offset(x: 3, y: 3)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(bill.rule.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text("\(bill.relativeTitle) · \(bill.date.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            AmountLabel(amount: bill.rule.kind == .expense ? -bill.rule.amount : bill.rule.amount,
                        sign: .always,
                        size: 15,
                        tint: .secondary,
                        unitOpacity: 0.6)
        }
        .padding(.vertical, 6)
    }
}
