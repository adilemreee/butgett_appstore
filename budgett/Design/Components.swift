//
//  Components.swift
//  Budgett
//
//  Shared building blocks: money labels, badges, gauges, pickers, empty states.
//

import SwiftUI

// MARK: - Money

struct AmountLabel: View {
    var amount: Decimal
    var sign: SignStyle = .none
    var size: CGFloat = 34
    var tint: Color?
    var unitOpacity: Double = 0.45

    @Environment(\.settings) private var settings

    var body: some View {
        let parts = Money.components(amount, settings: settings, sign: sign)
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if !parts.sign.isEmpty {
                Text(parts.sign)
                    .font(.system(size: size * 0.62, weight: .bold, design: .rounded))
                    .foregroundStyle(tint ?? .primary)
            }
            if !parts.unit.isEmpty {
                Text(parts.unit)
                    .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                    .foregroundStyle((tint ?? .primary).opacity(unitOpacity))
            }
            Text(parts.number)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(tint ?? .primary)
                .contentTransition(.numericText())
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }
}

// MARK: - Badges

struct CategoryBadge: View {
    var symbol: String
    var color: Color = .primary
    var size: CGFloat = 42
    var filled: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(filled ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.primary.opacity(0.07)))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(filled ? Color(.systemBackground) : Color.primary)
            }
    }
}

struct TagChip: View {
    var text: String
    var color: Color = .secondary

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .foregroundStyle(color)
    }
}

// MARK: - Headers

struct SectionHeader: View {
    var title: String
    var trailing: String?
    var trailingColor: Color = .secondary

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.6)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(trailingColor)
            }
        }
    }
}

// MARK: - Segmented control

struct GlassSegmented<Value: Hashable>: View {
    var options: [Value]
    var title: (Value) -> String
    @Binding var selection: Value

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isActive = option == selection
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selection = option
                    }
                    Haptics.selection()
                } label: {
                    Text(title(option))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isActive ? Color(.systemBackground) : Color.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(Color.primary)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }
}

// MARK: - Gauges

/// Semi-circular budget gauge with a soft track and rounded progress cap.
struct ArcGauge: View {
    var progress: Double
    var lineWidth: CGFloat = 16
    var tint: Color = .primary
    var trackTint: Color = Color.primary.opacity(0.08)

    private let span: Double = 0.72   // fraction of the circle used

    var body: some View {
        ZStack {
            arc(1)
                .stroke(trackTint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            arc(min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        }
        .rotationEffect(.degrees(90 + (1 - span) * 180))
        .aspectRatio(1, contentMode: .fit)
    }

    private func arc(_ amount: Double) -> some Shape {
        Circle().trim(from: 0, to: span * amount)
    }
}

struct RingProgress: View {
    var progress: Double
    var lineWidth: CGFloat = 10
    var tint: Color = .primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
        }
    }
}

/// Thin capsule progress bar with an optional pace marker.
struct BudgetBar: View {
    var progress: Double
    var tint: Color
    var marker: Double?
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)
                if let marker, marker > 0, marker < 1 {
                    Rectangle()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: 2, height: height + 6)
                        .offset(x: geo.size.width * marker - 1)
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Stat tiles

struct StatTile: View {
    var title: String
    var amount: Decimal
    var symbol: String
    var isCurrency: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                if isCurrency {
                    AmountLabel(amount: amount, size: 16, tint: .primary, unitOpacity: 0.4)
                } else {
                    Text(Money.number(amount, showCents: false))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Text(message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.inkProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
    }
}

// MARK: - Pickers

struct SymbolGrid: View {
    var symbols: [String]
    @Binding var selection: String
    var tint: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(symbols, id: \.self) { symbol in
                Button {
                    selection = symbol
                    Haptics.selection()
                } label: {
                    Image(systemName: symbol)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(selection == symbol ? Color(.systemBackground) : Color.primary)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(selection == symbol ? AnyShapeStyle(Color.primary) : AnyShapeStyle(Color.primary.opacity(0.06)))
                        }
                }
                .buttonStyle(.pressable)
            }
        }
    }
}

// MARK: - Share sheet

struct ShareLinkSheet: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
