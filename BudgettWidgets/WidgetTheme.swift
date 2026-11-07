//
//  WidgetTheme.swift
//  BudgettWidgets
//
//  Small styling helpers. Deliberately independent from the app target so the
//  extension stays lean; only WidgetBridge.swift is shared.
//

import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 6 { s.append("FF") }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        self.init(.sRGB,
                  red: Double((value & 0xFF00_0000) >> 24) / 255,
                  green: Double((value & 0x00FF_0000) >> 16) / 255,
                  blue: Double((value & 0x0000_FF00) >> 8) / 255,
                  opacity: Double(value & 0x0000_00FF) / 255)
    }
}

enum WidgetPalette {
    static let income = Color.primary
    static let expense = Color.primary
    static let warning = Color.primary

    /// Grayscale steps so stacked series stay legible without hue.
    static func shade(_ index: Int) -> Color {
        let steps: [Double] = [1.0, 0.74, 0.56, 0.42, 0.32, 0.25]
        return Color.primary.opacity(steps[min(index, steps.count - 1)])
    }
}

extension BudgettSnapshot {
    var accent: Color { .primary }
    var budgetTint: Color { .primary }
}

// MARK: - Pieces

/// Semi-circular gauge matching the one on the Budgets tab.
struct WidgetArcGauge: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color

    private let span: Double = 0.72

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: span)
                .stroke(tint.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: span * min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .rotationEffect(.degrees(90 + (1 - span) * 180))
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Seven-day spend sparkline.
struct WidgetBars: View {
    var days: [BudgettSnapshot.Day]
    var tint: Color
    var showLabels: Bool = true
    var barCorner: CGFloat = 3

    private var maxValue: Double {
        max(days.map { decimalToDouble($0.amount) }.max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let labelHeight: CGFloat = showLabels ? 12 : 0
            let chartHeight = max(6, geo.size.height - labelHeight)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days) { day in
                    VStack(spacing: 3) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: barCorner, style: .continuous)
                            .fill(isToday(day.date)
                                  ? AnyShapeStyle(tint)
                                  : AnyShapeStyle(tint.opacity(0.42)))
                            .frame(height: max(3, chartHeight * (decimalToDouble(day.amount) / maxValue)))
                        if showLabels {
                            Text(weekday(day.date))
                                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(height: labelHeight - 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func isToday(_ date: Date) -> Bool { Calendar.current.isDateInToday(date) }

    private func weekday(_ date: Date) -> String {
        String(date.formatted(.dateTime.weekday(.narrow)))
    }
}

struct WidgetGlyph: View {
    var symbol: String
    var color: Color
    var size: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(color.opacity(0.18))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(color)
            }
    }
}

struct WidgetHeader: View {
    var title: String
    var symbol: String
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

/// Currency unit rendered smaller than the number, like the app does.
struct WidgetAmount: View {
    var text: String
    var size: CGFloat
    var tint: Color = .primary

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
