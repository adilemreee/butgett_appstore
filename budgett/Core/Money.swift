//
//  Money.swift
//  Budgett
//
//  Decimal formatting helpers. Amounts are always stored positive; the sign is
//  derived from the transaction kind at display time.
//

import Foundation

enum SignStyle {
    case none          // 12,50
    case negativeOnly  // -12,50
    case always        // +12,50 / -12,50
}

enum Money {
    // MARK: Symbols

    private static var symbolCache: [String: String] = [:]

    static func symbol(for code: String) -> String {
        if let cached = symbolCache[code] { return cached }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        let symbol = f.currencySymbol ?? code
        // Some locales return "TRY" style symbols with the code embedded.
        let cleaned = symbol.trimmingCharacters(in: .whitespaces)
        symbolCache[code] = cleaned
        return cleaned
    }

    static func name(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    // MARK: Numbers

    private static var formatterCache: [Int: NumberFormatter] = [:]

    private static func formatter(fraction: Int) -> NumberFormatter {
        if let f = formatterCache[fraction] { return f }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.minimumFractionDigits = fraction
        f.maximumFractionDigits = fraction
        formatterCache[fraction] = f
        return f
    }

    /// Digits only, e.g. `1.234,50`.
    static func number(_ amount: Decimal, showCents: Bool = true) -> String {
        let value = abs(amount)
        let fraction = showCents ? 2 : 0
        return formatter(fraction: fraction).string(from: value as NSDecimalNumber) ?? "0"
    }

    /// Fully decorated amount honouring the user's currency preferences.
    static func string(_ amount: Decimal,
                       settings: AppSettings = .shared,
                       sign: SignStyle = .none,
                       code: String? = nil) -> String {
        let parts = components(amount, settings: settings, sign: sign, code: code)
        return [parts.sign, parts.unit, parts.number]
            .filter { !$0.isEmpty }
            .joined(separator: parts.unit.isEmpty ? "" : " ")
    }

    struct Components {
        var sign: String
        var unit: String
        var number: String
    }

    static func components(_ amount: Decimal,
                           settings: AppSettings = .shared,
                           sign: SignStyle = .none,
                           code: String? = nil) -> Components {
        let currency = code ?? settings.currencyCode
        let unit: String
        switch settings.currencyPresentation {
        case .symbol: unit = symbol(for: currency)
        case .code: unit = currency
        case .none: unit = ""
        }
        var prefix = ""
        switch sign {
        case .none: prefix = ""
        case .negativeOnly: prefix = amount < 0 ? "-" : ""
        case .always: prefix = amount < 0 ? "-" : "+"
        }
        let digits = settings.privacyMode ? "••••" : number(amount, showCents: settings.showCents)
        return Components(sign: prefix, unit: unit, number: digits)
    }

    /// Compact form used on chart axes: 1,2B / 340
    static func compact(_ amount: Decimal) -> String {
        let value = (abs(amount) as NSDecimalNumber).doubleValue
        switch value {
        case 1_000_000...:
            return String(format: "%.1fM", value / 1_000_000)
        case 10_000...:
            return String(format: "%.0fB", value / 1_000)
        case 1_000...:
            return String(format: "%.1fB", value / 1_000)
        default:
            return String(format: "%.0f", value)
        }
    }

    // MARK: Parsing

    static func decimal(from text: String) -> Decimal {
        let normalized = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." || $0 == "-" }
        return Decimal(string: normalized) ?? 0
    }
}

extension Decimal {
    var doubleValue: Double { (self as NSDecimalNumber).doubleValue }

    func rounded(_ scale: Int = 2) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }
}
