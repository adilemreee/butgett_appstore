//
//  WatchTheme.swift
//  BudgettWatch
//
//  Small styling helpers, monochrome like the iOS app. Deliberately independent
//  from the app target; only WidgetBridge.swift is shared.
//

import SwiftUI
import Foundation

enum WatchPalette {
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
}

// MARK: - Card

/// The watch version of the app's single quiet card.
struct WatchCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.07))
            }
    }
}

extension View {
    func watchCard() -> some View {
        modifier(WatchCard())
    }
}

// MARK: - Pieces

/// Semi-circular gauge matching the one on the Budgets tab.
struct WatchArcGauge: View {
    var progress: Double
    var lineWidth: CGFloat = 8
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

/// Seven-day spend sparkline, today highlighted.
struct WatchBars: View {
    var days: [BudgettSnapshot.Day]
    var tint: Color
    var barCorner: CGFloat = 2

    private var maxValue: Double {
        max(days.map { decimalToDouble($0.amount) }.max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: barCorner, style: .continuous)
                        .fill(isToday(day.date)
                              ? AnyShapeStyle(tint)
                              : AnyShapeStyle(tint.opacity(0.4)))
                        .frame(height: max(2, geo.size.height * (decimalToDouble(day.amount) / maxValue)))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func isToday(_ date: Date) -> Bool { Calendar.current.isDateInToday(date) }
}

/// Small rounded symbol badge, grayscale like the app's rows.
struct WatchGlyph: View {
    var symbol: String
    var size: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
            .fill(Color.primary.opacity(0.16))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(Color.primary)
            }
    }
}

// MARK: - Press feedback

/// Subtle press feedback, matching the app's own pressable style. No white
/// flash, just a quiet dim + shrink.
struct WatchPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == WatchPressableStyle {
    static var watchPressable: WatchPressableStyle { WatchPressableStyle() }
}
