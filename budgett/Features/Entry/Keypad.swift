//
//  Keypad.swift
//  Budgett
//

import SwiftUI

struct Keypad: View {
    var style: KeypadStyle
    var canSubmit: Bool
    var isResolving: Bool = false
    var onKey: (KeypadKey) -> Void

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
    private let ops: [CalcOp] = [.divide, .multiply, .subtract, .add]

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 9) {
                VStack(spacing: 9) {
                    ForEach(rows.indices, id: \.self) { index in
                        HStack(spacing: 9) {
                            ForEach(rows[index], id: \.self) { digit in
                                key(title: digit) { onKey(.digit(digit)) }
                            }
                        }
                    }
                    HStack(spacing: 9) {
                        key(title: Locale.current.decimalSeparator ?? ",") { onKey(.decimal) }
                        key(title: "0") { onKey(.digit("0")) }
                        key(symbol: "delete.left") { onKey(.backspace) }
                    }
                }

                if style == .calculator {
                    VStack(spacing: 9) {
                        ForEach(ops, id: \.self) { op in
                            key(title: op.rawValue, tint: Color.primary.opacity(0.10), foreground: .primary) {
                                onKey(.op(op))
                            }
                        }
                    }
                    .frame(width: 68)
                }
            }

            submitButton
        }
    }

    private var submitButton: some View {
        Button {
            onKey(.submit)
        } label: {
            Label(isResolving ? "Hesapla" : "Kaydet", systemImage: isResolving ? "equal" : "checkmark")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(Color(.systemBackground))
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary)
                        .opacity(canSubmit ? 1 : 0.3)
                }
        }
        .buttonStyle(.pressable)
        .disabled(!canSubmit)
        
    }

    private func key(title: String? = nil,
                     symbol: String? = nil,
                     tint: Color? = nil,
                     foreground: Color? = nil,
                     action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.tap(.light)
        } label: {
            Group {
                if let title {
                    Text(title)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 20, weight: .medium))
                }
            }
            .foregroundStyle(foreground ?? .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint ?? Color.primary.opacity(0.06))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
    }
}
