//
//  InsightCards.swift
//  BudgettWidgets
//
//  The two charts the analytics tab is built from.
//

import SwiftUI
import Charts

// MARK: - Spending chart

struct SpendChartCard: View {
    var buckets: [TimeBucket]
    var period: Period
    var average: Decimal

    @State private var selectedDate: Date?

    private var maxValue: Double {
        max(buckets.map { $0.expense.doubleValue }.max() ?? 0, 1)
    }

    private var selected: TimeBucket? {
        guard let selectedDate else { return nil }
        return buckets.min {
            abs($0.start.timeIntervalSince(selectedDate)) < abs($1.start.timeIntervalSince(selectedDate))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(selected == nil ? "Harcama akışı" : selected!.start.formatted(labelStyle))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                AmountLabel(amount: selected?.expense ?? buckets.reduce(Decimal(0)) { $0 + $1.expense },
                            size: 17)
            }

            Chart {
                ForEach(buckets) { bucket in
                    BarMark(
                        x: .value("Tarih", bucket.start, unit: period.bucket),
                        y: .value("Gider", bucket.expense.doubleValue)
                    )
                    .foregroundStyle(Color.primary.opacity(barOpacity(for: bucket)))
                    .cornerRadius(4)
                }

                if average > 0 {
                    RuleMark(y: .value("Ortalama", average.doubleValue))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .chartYScale(domain: 0...(maxValue * 1.2))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(Money.compact(Decimal(number)))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                    AxisValueLabel()
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(height: 150)
        }
        .padding(16)
        .glassCard()
    }

    private var labelStyle: Date.FormatStyle {
        switch period {
        case .day: .dateTime.hour()
        case .week, .month: .dateTime.weekday(.wide).day().month(.abbreviated)
        case .year, .all: .dateTime.month(.wide).year()
        }
    }

    private func barOpacity(for bucket: TimeBucket) -> Double {
        guard selected != nil else { return 0.85 }
        return selected?.id == bucket.id ? 1 : 0.22
    }
}

// MARK: - Category breakdown

struct CategoryBreakdownCard: View {
    var slices: [CategorySlice]
    var total: Decimal
    var kind: TxnKind
    var onSelect: (CategorySlice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(kind == .expense ? "Kategoriler" : "Gelir kaynakları")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            if slices.isEmpty {
                Text("Bu dönem için veri yok.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                stackedBar
                legend
            }
        }
        .padding(16)
        .glassCard()
    }

    private var visible: [CategorySlice] { Array(slices.prefix(6)) }

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, slice in
                    Capsule()
                        .fill(Palette.shade(index))
                        .frame(width: max(6, geo.size.width * slice.share - 3))
                }
            }
        }
        .frame(height: 14)
    }

    private var legend: some View {
        VStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, slice in
                Button {
                    onSelect(slice)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Palette.shade(index))
                            .frame(width: 9, height: 9)
                        Text(slice.name)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary)
                        Spacer(minLength: 6)
                        Text("%\(Int(slice.share * 100))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        AmountLabel(amount: slice.total, size: 14)
                            .frame(minWidth: 92, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < visible.count - 1 {
                    Divider().opacity(0.5)
                }
            }
        }
    }
}
