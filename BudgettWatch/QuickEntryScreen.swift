//
//  QuickEntryScreen.swift
//  BudgettWatch
//
//  A minimal expense/income capture: pick a direction, dial the amount with the
//  Digital Crown, and hand it to the phone over WatchConnectivity.
//

import SwiftUI
import WatchKit

struct QuickEntryScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isIncome = false
    @State private var amount: Double = 100
    @State private var phase: Phase = .idle

    private enum Phase {
        case idle, sending, done, failed
    }

    private var snapshot: BudgettSnapshot? { WatchSyncStore.shared.snapshot }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                kindChip("Gider", icon: "arrow.down.left", selected: !isIncome) { isIncome = false }
                kindChip("Gelir", icon: "arrow.up.right", selected: isIncome) { isIncome = true }
            }

            Text(moneyString)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .focusable()
                .digitalCrownRotation($amount, from: 5, through: 500_000, by: 5,
                                     sensitivity: .medium, isContinuous: false)

            Spacer(minLength: 0)

            Button(action: save) {
                Group {
                    switch phase {
                    case .idle: Label("Kaydet", systemImage: "checkmark")
                    case .sending: ProgressView().tint(.primary)
                    case .done: Label("Eklendi", systemImage: "checkmark.circle.fill")
                    case .failed: Label("Tekrar dene", systemImage: "exclamationmark.circle.fill")
                    }
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.18))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
                }
                .foregroundStyle(Color.primary)
            }
            .buttonStyle(.watchPressable)
            .disabled(phase == .sending || amount <= 0)
        }
        .padding(.horizontal, 6)
        .navigationTitle(isIncome ? "Gelir" : "Gider")
        .onAppear { phase = .idle }
    }

    private func kindChip(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? Color.primary.opacity(0.24) : Color.primary.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(selected ? 0.5 : 0.12), lineWidth: 1)
                }
                .foregroundStyle(selected ? Color.primary : Color.secondary)
        }
        .buttonStyle(.watchPressable)
    }

    private var moneyString: String {
        let symbol = snapshot?.currencySymbol ?? "₺"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        let digits = formatter.string(from: NSDecimalNumber(value: amount)) ?? "0"
        return "\(symbol) \(digits)"
    }

    private func save() {
        guard amount > 0, phase != .sending else { return }
        phase = .sending

        let value = Decimal(Int(amount.rounded()))
        WatchSyncStore.shared.addTransaction(amount: value, isIncome: isIncome) { ok in
            phase = ok ? .done : .failed
            if ok {
                WKInterfaceDevice.current().play(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    dismiss()
                }
            }
        }
    }
}
