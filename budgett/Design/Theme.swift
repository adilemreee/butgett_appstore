//
//  Theme.swift
//  Budgett
//
//  Monochrome design system. The app draws in ink and paper only; meaning comes
//  from weight, size and grayscale steps rather than hue.
//

import SwiftUI

// MARK: - Color <-> Hex

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 6 { s.append("FF") }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value & 0xFF00_0000) >> 24) / 255
        let g = Double((value & 0x00FF_0000) >> 16) / 255
        let b = Double((value & 0x0000_FF00) >> 8) / 255
        let a = Double(value & 0x0000_00FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Appearance

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Sistem"
        case .light: "Açık"
        case .dark: "Koyu"
        }
    }

    var symbol: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Accent

/// The app is single-tone; the type is kept so every call site can keep asking
/// for "the accent" without caring that there is only one.
enum ThemeAccent: String, CaseIterable, Identifiable, Codable {
    case mono

    var id: String { rawValue }
    var title: String { "Tek renk" }
    var hex: String { "111113" }
    var color: Color { .primary }
    var secondary: Color { .secondary }
}

// MARK: - Semantic tokens

enum Palette {
    /// Amounts never rely on hue — direction is carried by the +/− sign.
    static let income = Color.primary
    static let expense = Color.primary
    static let transfer = Color.secondary
    static let warning = Color.primary

    /// Distinct grayscale steps for stacked bars and legends.
    static func shade(_ index: Int) -> Color {
        let steps: [Double] = [1.0, 0.74, 0.56, 0.42, 0.32, 0.25, 0.19, 0.14]
        return Color.primary.opacity(steps[min(index, steps.count - 1)])
    }

    /// Tint for controls that fill their background with the tint (switches,
    /// date pickers). `Color.primary` would turn those white in dark mode and
    /// make the white knob/label disappear.
    static let controlTint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.45, alpha: 1)
            : UIColor(white: 0.09, alpha: 1)
    })

    /// Solid fill for destructive/neutral action buttons where the system
    /// always draws a white label (e.g. swipe actions).
    static let actionFill = Color(white: 0.32)

    static let categorySymbols: [String] = [
        "fork.knife", "cart", "house", "car", "bus", "tram",
        "airplane", "fuelpump", "cup.and.saucer", "wineglass",
        "bag", "tshirt", "gift", "gamecontroller", "film",
        "music.note", "book", "graduationcap", "cross.case", "pills",
        "dumbbell", "pawprint", "leaf", "wrench.and.screwdriver",
        "bolt", "drop", "flame", "wifi", "iphone", "desktopcomputer",
        "creditcard", "banknote", "chart.line.uptrend.xyaxis", "briefcase",
        "scissors", "sparkles", "figure.and.child.holdinghands", "heart",
        "ticket", "camera", "hammer", "shippingbox"
    ]

    static let walletSymbols: [String] = [
        "banknote", "creditcard", "building.columns", "wallet.bifold",
        "bitcoinsign.circle", "chart.pie", "lock", "shippingbox",
        "iphone", "gift", "star", "sparkles"
    ]

    static let goalSymbols: [String] = [
        "target", "airplane", "house", "car", "graduationcap",
        "gift", "camera", "laptopcomputer", "cross.case", "heart",
        "beach.umbrella", "sparkles"
    ]
}

// MARK: - Typography

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Layout constants

enum Metrics {
    static let cardRadius: CGFloat = 24
    static let smallRadius: CGFloat = 16
    static let hPadding: CGFloat = 18
    /// Clearance under scroll content so the floating bar never covers the last row.
    static let tabBarClearance: CGFloat = 104
}
