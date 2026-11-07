//
//  AmountEntry.swift
//  Budgett
//
//  Tiny calculator that backs the entry keypad.
//

import Foundation

enum CalcOp: String, CaseIterable {
    case add = "+", subtract = "−", multiply = "×", divide = "÷"

    func apply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {
        switch self {
        case .add: lhs + rhs
        case .subtract: lhs - rhs
        case .multiply: lhs * rhs
        case .divide: rhs == 0 ? lhs : lhs / rhs
        }
    }
}

enum KeypadKey: Hashable {
    case digit(String)
    case decimal
    case backspace
    case op(CalcOp)
    case equals
    case submit
}

struct AmountEntry {
    private(set) var current: String = "0"
    private(set) var stored: Decimal?
    private(set) var pendingOp: CalcOp?

    private let maxIntegerDigits = 12
    private let maxFractionDigits = 2

    var value: Decimal {
        let result = Money.decimal(from: current)
        return result.rounded(maxFractionDigits)
    }

    var isEmpty: Bool { value == 0 }
    var hasPendingOperation: Bool { pendingOp != nil }

    /// The formatted number shown in the giant label.
    var displayText: String {
        let separator = Locale.current.decimalSeparator ?? ","
        let pieces = current.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = Decimal(string: String(pieces.first ?? "0")) ?? 0
        let grouped = Money.number(integerPart, showCents: false)
        guard current.contains(".") else { return grouped }
        let fraction = pieces.count > 1 ? String(pieces[1]) : ""
        return grouped + separator + fraction
    }

    /// Secondary line: `1.250 +`
    var expressionText: String? {
        guard let stored, let pendingOp else { return nil }
        return "\(Money.number(stored, showCents: stored != stored.rounded(0))) \(pendingOp.rawValue)"
    }

    mutating func reset(to amount: Decimal = 0) {
        stored = nil
        pendingOp = nil
        if amount == 0 {
            current = "0"
        } else {
            let rounded = amount.rounded(maxFractionDigits)
            var text = "\(rounded)"
            if text.hasSuffix(".0") { text.removeLast(2) }
            current = text
        }
    }

    mutating func input(_ key: KeypadKey) {
        switch key {
        case .digit(let digit):
            appendDigit(digit)
        case .decimal:
            if !current.contains(".") { current += "." }
        case .backspace:
            if current.count <= 1 || (current.count == 2 && current.hasPrefix("-")) {
                current = "0"
            } else {
                current.removeLast()
                if current.hasSuffix(".") { current.removeLast() }
                if current.isEmpty { current = "0" }
            }
        case .op(let op):
            if let stored, let pendingOp {
                let result = pendingOp.apply(stored, value)
                self.stored = result
            } else {
                stored = value
            }
            pendingOp = op
            current = "0"
        case .equals:
            resolve()
        case .submit:
            resolve()
        }
    }

    mutating func resolve() {
        guard let stored, let pendingOp else { return }
        let result = pendingOp.apply(stored, value).rounded(maxFractionDigits)
        var text = "\(result)"
        if text.hasSuffix(".0") { text.removeLast(2) }
        current = text
        self.stored = nil
        self.pendingOp = nil
    }

    private mutating func appendDigit(_ digit: String) {
        if let dotIndex = current.firstIndex(of: ".") {
            let fraction = current.distance(from: current.index(after: dotIndex), to: current.endIndex)
            guard fraction < maxFractionDigits else { return }
        } else {
            let digits = current.filter(\.isNumber).count
            guard digits < maxIntegerDigits else { return }
        }
        if current == "0" {
            current = digit
        } else {
            current += digit
        }
    }
}
